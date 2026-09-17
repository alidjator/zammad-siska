# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Runs periodically via Scheduler (see docs/DESIGN_ESCALATION_STATUS.md).
# Computes ticket.escalation_deadline_at for every ticket currently in the
# "eskalasi" state that has escalation_started_at set -- a FIXED deadline
# (escalation_started_at + effective budget hours), not a continuously
# recalculated "time remaining".
#
# Effective budget: Group#escalation_budget_hours overrides
# Organization#escalation_budget_hours overrides the global Setting
# escalation_budget_hours (default 8) -- see
# script/create_escalation_object_attributes.rb.
#
# Business-hours aware: uses the same Biz::Schedule mechanism native
# Zammad SLA escalation uses (Escalation::DestinationTime, lib/escalation/
# destination_time.rb: `biz.time(minutes, :minutes).after(start_time)`),
# via the ticket's own matching Sla's Calendar (same Sla.for_ticket(ticket)
# lookup native escalation uses), falling back to the system default
# Calendar if the ticket doesn't match any Sla. This is NOT a naive
# `escalation_started_at + N.hours` -- that would count nights/weekends/
# holidays the same as business hours, unlike the native SLA clock it's
# meant to complement.
#
# Always recomputes (idempotent, only writes if the value actually
# changed) rather than only acting on rows where escalation_deadline_at
# is still nil -- this correctly re-derives the deadline if a ticket
# re-enters Eskalasi later (escalation_started_at gets refreshed by the
# Trigger on each re-entry) without needing separate "is this stale"
# tracking.
class Service::Escalation::CalculateDeadlines
  def self.run
    new.run
  end

  def run
    Ticket.where(state_id: eskalasi_state_id)
          .where.not(escalation_started_at: nil)
          .find_each do |ticket|
      new_deadline = deadline_for(ticket)
      next if ticket.escalation_deadline_at == new_deadline

      ticket.update_columns(escalation_deadline_at: new_deadline) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  private

  def eskalasi_state_id
    @eskalasi_state_id ||= Ticket::State.find_by!(name: 'eskalasi').id
  end

  def deadline_for(ticket)
    budget_minutes = effective_budget_hours(ticket) * 60
    schedule       = biz_schedule_for(ticket)

    return ticket.escalation_started_at + budget_minutes.minutes if schedule.blank?

    schedule.time(budget_minutes, :minutes).after(ticket.escalation_started_at)
  end

  def effective_budget_hours(ticket)
    ticket.group&.escalation_budget_hours ||
      ticket.organization&.escalation_budget_hours ||
      Setting.get('escalation_budget_hours').to_i
  end

  def biz_schedule_for(ticket)
    calendar = Sla.for_ticket(ticket)&.calendar || Calendar.default
    calendar&.biz
  end
end
