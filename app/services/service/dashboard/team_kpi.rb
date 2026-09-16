# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Team-wide operational KPI for the "KPI Tim" Dashboard tab (see
# docs/DESIGN_TEAM_KPI_DASHBOARD.md) -- gap analysis item No. 8.
#
# FRT and CSAT use a rolling window, selectable from the dashboard's range
# dropdown (default 7 days, up to 2 years retroactive). A rolling window
# gives a consistent sample size every day, unlike month-to-date (early in
# the month = misleading average from too few days). Ticket state counts
# are always a real-time snapshot regardless of the range filter -- "how
# many are open right now" doesn't have a meaningful historical variant.
#
# FRT median is computed in SQL (percentile_cont) rather than pulled into
# Ruby, since a 2-year window can span hundreds of thousands of tickets.
class Service::Dashboard::TeamKpi
  DEFAULT_WINDOW_DAYS = 7
  MAX_WINDOW_DAYS      = 730 # 2 tahun

  def self.call(window_days: DEFAULT_WINDOW_DAYS)
    new(window_days).call
  end

  def initialize(window_days)
    @window_days = window_days.to_i.clamp(1, MAX_WINDOW_DAYS)
  end

  def call
    {
      frt_median_minutes: frt_median_minutes,
      csat_average:       csat_average,
      ticket_new:         ticket_count_by_state_type('new'),
      ticket_open:        ticket_count_by_state_type('open'),
      ticket_escalated:   ticket_escalated_count,
      window_days:        @window_days,
      generated_at:       Time.zone.now.iso8601,
    }
  end

  private

  def since
    @since ||= @window_days.days.ago
  end

  # Mirrors Report::TicketFirstResponseTime's data-integrity filter (see
  # docs/BUG_REPORT_TIMEZONE_FIRST_RESPONSE.md): exclude tickets where
  # first_response_at < created_at (known ~7h timezone bug).
  def frt_median_minutes
    sql = <<~SQL.squish
      SELECT percentile_cont(0.5) WITHIN GROUP (
        ORDER BY EXTRACT(EPOCH FROM (first_response_at - created_at)) / 60
      )
      FROM tickets
      WHERE first_response_at IS NOT NULL
        AND first_response_at >= created_at
        AND created_at >= ?
    SQL

    result = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql_array([sql, since])
    )
    result.nil? ? nil : result.to_f.round(1)
  end

  def csat_average
    sql = <<~SQL.squish
      SELECT AVG(csat_score)
      FROM tickets
      WHERE csat_score IS NOT NULL
        AND csat_submitted_at >= ?
    SQL

    result = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql_array([sql, since])
    )
    result.nil? ? nil : result.to_f.round(2)
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
