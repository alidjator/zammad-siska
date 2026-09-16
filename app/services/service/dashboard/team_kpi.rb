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
#
# `*_state` fields (supergood/good/ok/bad/superbad/nil) mirror the native
# "My Stats" widgets' own color-coding convention (lib/stats/ticket_*.rb),
# so the frontend can reuse Zammad's own --supergood-color..--superbad-color
# CSS variables instead of inventing new colors. Thresholds:
#   - FRT: absolute cutoffs adapted from lib/stats/ticket_waiting_time.rb's
#     handling-time bands (<=60/240/480 min), extended with a "superbad"
#     tier (>1440 min) since our rolling-window median can run far higher
#     than a single day's average handling time.
#   - CSAT: no native precedent (no equivalent widget) -- generic 1-5 CSAT
#     industry bands.
#   - Escalated: reuses lib/stats/ticket_reopen.rb's rate bucket exactly
#     (>=20/40/65/90%), applied to escalated-as-percent-of-open+new since
#     that's a rate metric like reopening rate, not a per-agent raw count
#     like the native Mood widget.
#   - New/Open ticket counts are left uncolored (state: nil) -- they are
#     raw volume snapshots, not a performance measure with an inherent
#     "good/bad" direction (native itself leaves some widgets, e.g.
#     Channel Distribution, uncolored for the same reason).
# See docs/DESIGN_TEAM_KPI_DASHBOARD.md for the full rationale and the
# calibration data behind these thresholds.
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
    frt         = frt_median_minutes
    csat        = csat_average
    new_count   = ticket_count_by_state_type('new')
    open_count  = ticket_count_by_state_type('open')
    escalated   = ticket_escalated_count
    escalation_rate = escalation_rate_percent(escalated, new_count, open_count)

    {
      frt_median_minutes:     frt,
      frt_state:              frt_state(frt),
      csat_average:           csat,
      csat_state:             csat_state(csat),
      ticket_new:             new_count,
      ticket_open:            open_count,
      ticket_escalated:       escalated,
      escalation_rate_percent: escalation_rate,
      escalated_state:        escalated_state(escalation_rate),
      window_days:            @window_days,
      generated_at:           Time.zone.now.iso8601,
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

  def escalation_rate_percent(escalated, new_count, open_count)
    denom = new_count + open_count
    return 0.0 if denom.zero?

    (escalated.to_f / denom * 100).round(1)
  end

  def frt_state(minutes)
    return nil if minutes.nil?

    if minutes <= 60
      'supergood'
    elsif minutes <= 240
      'good'
    elsif minutes <= 480
      'ok'
    elsif minutes <= 1440
      'bad'
    else
      'superbad'
    end
  end

  def csat_state(average)
    return nil if average.nil?

    if average >= 4.5
      'supergood'
    elsif average >= 4.0
      'good'
    elsif average >= 3.0
      'ok'
    elsif average >= 2.0
      'bad'
    else
      'superbad'
    end
  end

  def escalated_state(rate_percent)
    if rate_percent >= 90
      'superbad'
    elsif rate_percent >= 65
      'bad'
    elsif rate_percent >= 40
      'ok'
    elsif rate_percent >= 20
      'good'
    else
      'supergood'
    end
  end
end
