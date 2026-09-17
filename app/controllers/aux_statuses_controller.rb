# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). See
# docs/DESIGN_AUX_STATUS.md Section 5.7. Both actions are thin wrappers
# around Service::AuxStatus::ChangeStatus, which does the actual
# self-or-override authorization check -- Exceptions::Forbidden /
# Exceptions::UnprocessableContent it raises are already handled
# globally by ApplicationController::HandlesErrors, no local rescue
# needed here.
class AuxStatusesController < ApplicationController
  prepend_before_action :authentication_check

  # PUT /api/v1/aux_status
  # Ubah status milik diri sendiri.
  def update
    raise Exceptions::Forbidden if !current_user.permissions?('ticket.agent')

    user = Service::AuxStatus::ChangeStatus.run(
      target:     current_user,
      status:     params[:status],
      changed_by: current_user,
    )
    render json: status_json(user), status: :ok
  end

  # PUT /api/v1/aux_status/:user_id
  # Override status milik agent lain -- butuh permission 'aux_status.override'
  # (dicek di dalam Service::AuxStatus::ChangeStatus#authorize!, bukan di
  # sini, supaya jalur otorisasinya satu-satunya/tidak terduplikasi).
  def override
    raise Exceptions::Forbidden if !current_user.permissions?('ticket.agent')

    target = User.find(params[:user_id])
    user   = Service::AuxStatus::ChangeStatus.run(
      target:,
      status:     params[:status],
      changed_by: current_user,
    )
    render json: status_json(user), status: :ok
  end

  private

  # id (not just user_id) is required so the frontend can feed this
  # straight into App.User.refresh([...]) -- Spine collections match
  # records by `id`, not an arbitrary key.
  def status_json(user)
    {
      id:                    user.id,
      user_id:               user.id,
      aux_status:            user.aux_status,
      aux_status_since:      user.aux_status_since,
      aux_status_expires_at: user.aux_status_expires_at,
    }
  end
end
