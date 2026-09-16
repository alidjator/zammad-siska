# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Team-wide operational KPI for the "KPI Tim" Dashboard tab (see
# docs/DESIGN_TEAM_KPI_DASHBOARD.md) -- gap analysis item No. 8.
#
# FRT and CSAT use a rolling 7-day window (consistent sample size every
# day, avoids the "early month = misleading average" problem of
# month-to-date). Ticket state counts are a real-time snapshot, matching
# the "realtime dashboard" requirement.
class Service::Dashboard::TeamKpi
  ROLLING_WINDOW = 7.days.freeze

  def self.call
    new.call
  end

  def call
    {
      frt_median_minutes: frt_median_minutes,
      csat_average:       csat_average,
      ticket_new:         ticket_count_by_state_type('new'),
      ticket_open:        ticket_count_by_state_type('open'),
      ticket_escalated:   ticket_escalated_count,
      window_days:        ROLLING_WINDOW.in_days.to_i,
      generated_at:       Time.zone.now.iso8601,
    }
  end

  private

  # Mirrors Report::TicketFirstResponseTime's data-integrity filter (see
  # docs/BUG_REPORT_TIMEZONE_FIRST_RESPONSE.md) and median-over-mean choice.
  def frt_median_minutes
    diffs = Ticket
      .where(
        'tickets.first_response_at IS NOT NULL AND tickets.first_response_at >= tickets.created_at AND tickets.created_at >= ?',
        ROLLING_WINDOW.ago,
      )
      .pluck(:created_at, :first_response_at)
      .map { |created_at, first_response_at| first_response_at - created_at }

    return nil if diffs.blank?

    sorted = diffs.sort
    mid    = sorted.length / 2
    median = sorted.length.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0

    (median / 60).round(1)
  end

  def csat_average
    scores = Ticket
      .where('tickets.csat_score IS NOT NULL AND tickets.csat_submitted_at >= ?', ROLLING_WINDOW.ago)
      .pluck(:csat_score)

    return nil if scores.blank?

    (scores.sum.to_f / scores.size).round(2)
  end

  # Ticket::State.by_category(:open) lumps together new/open/pending
  # reminder/pending action -- we want "new" and "open" as distinct
  # buckets, so query by exact state_type name instead.
  def ticket_count_by_state_type(state_type_name)
    state_ids = Ticket::State.joins(:state_type).where(ticket_state_types: { name: state_type_name }).pluck(:id)
    Ticket.where(state_id: state_ids).count
  end

  def ticket_escalated_count
    Ticket
      .where.not(state_id: Ticket::State.by_category(:closed))
      .where.not(escalation_at: nil)
      .where(escalation_at: ..Time.zone.now)
      .count
  end
end
