# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). The single
# entry point for changing an agent's aux_status -- used by the API
# controller (self-service + supervisor override) AND by
# Service::AuxStatus::ExpireStatuses (system auto-revert, changed_by nil).
# See docs/DESIGN_AUX_STATUS.md Section 5.3.
class Service::AuxStatus::ChangeStatus
  def self.run(target:, status:, changed_by: nil)
    new(target:, status:, changed_by:).run
  end

  def initialize(target:, status:, changed_by:)
    @target     = target
    @status     = status.to_s
    @changed_by = changed_by
  end

  def run
    authorize!
    validate_status!

    AuxStatusLog.close_open_entry!(@target)
    AuxStatusLog.create!(
      user:       @target,
      status:     @status,
      changed_by: @changed_by,
      started_at: Time.zone.now,
    )

    @target.update!(
      aux_status:            @status,
      aux_status_since:      Time.zone.now,
      aux_status_expires_at: expires_at,
    )

    # Section 4 decision: going Available proactively pulls in a pending
    # unassigned ticket, if there's one waiting in a Group this agent has
    # access to.
    Service::AuxStatus::DistributeTicket.pending_for(@target) if @status == 'available'

    @target
  end

  private

  def authorize!
    return if @changed_by.nil? # system (Scheduler auto-expiry) -- always allowed
    return if @changed_by.id == @target.id
    return if @changed_by.permissions?('aux_status.override')

    raise Exceptions::Forbidden, 'Not allowed to change this user\'s AUX status.'
  end

  def validate_status!
    return if allowed_statuses.include?(@status)

    raise Exceptions::UnprocessableContent, "Unknown AUX status: #{@status}"
  end

  # Reads live from Setting aux_status_options -- an admin adding/
  # removing a status there (Admin > Settings > SISKA > AUX Status)
  # takes effect immediately, no code change or redeploy needed. See
  # script/create_aux_status_object_attributes.rb for why this Setting
  # is a JSON STRING, not a native Array/Hash.
  def allowed_statuses
    self.class.options.pluck('value')
  end

  def duration_minutes
    self.class.options.find { |option| option['value'] == @status }&.dig('duration_minutes').to_i
  end

  # Malformed JSON (an admin saved broken input) fails CLOSED (no
  # statuses allowed) rather than raising and breaking every status
  # change app-wide -- the Admin UI edit is what needs fixing, not this
  # code path.
  def self.options
    JSON.parse(Setting.get('aux_status_options').to_s)
  rescue JSON::ParserError
    []
  end

  def expires_at
    return if duration_minutes <= 0

    Time.zone.now + duration_minutes.minutes
  end
end
