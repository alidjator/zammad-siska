# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Team-wide operational KPI for the "KPI Tim" Dashboard tab (see
# docs/DESIGN_TEAM_KPI_DASHBOARD.md) -- gap analysis item No. 8.
#
# FRT and CSAT use a rolling window, selectable from the dashboard's range
# dropdown (default team_kpi_default_window_days, up to
# team_kpi_max_window_days retroactive). A rolling window gives a
# consistent sample size every day, unlike month-to-date (early in the
# month = misleading average from too few days). Ticket state counts
# are always a real-time snapshot regardless of the range filter -- "how
# many are open right now" doesn't have a meaningful historical variant.
#
# FRT median is computed in SQL (percentile_cont) rather than pulled into
# Ruby, since a 2-year window can span hundreds of thousands of tickets.
#
# `*_state` fields (supergood/good/ok/bad/superbad/nil) mirror the native
# "My Stats" widgets' own color-coding convention (lib/stats/ticket_*.rb),
# so the frontend can reuse Zammad's own --supergood-color..--superbad-color
# CSS variables instead of inventing new colors. Thresholds are Settings
# (team_kpi_frt_thresholds/team_kpi_csat_thresholds/
# team_kpi_escalated_thresholds -- see script/create_team_kpi_settings.rb,
# editable via Admin > Settings > SISKA > KPI Tim), not hardcoded, so they
# can be recalibrated without a redeploy. Defaults:
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
  def self.call(window_days: default_window_days)
    new(window_days).call
  end

  def self.default_window_days
    Setting.get('team_kpi_default_window_days').to_i
  end

  def self.max_window_days
    Setting.get('team_kpi_max_window_days').to_i
  end

  def initialize(window_days)
    @window_days = window_days.to_i.clamp(1, self.class.max_window_days)
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

    t = Setting.get('team_kpi_frt_thresholds')
    if minutes <= t['supergood_max'].to_f
      'supergood'
    elsif minutes <= t['good_max'].to_f
      'good'
    elsif minutes <= t['ok_max'].to_f
      'ok'
    elsif minutes <= t['bad_max'].to_f
      'bad'
    else
      'superbad'
    end
  end

  def csat_state(average)
    return nil if average.nil?

    t = Setting.get('team_kpi_csat_thresholds')
    if average >= t['supergood_min'].to_f
      'supergood'
    elsif average >= t['good_min'].to_f
      'good'
    elsif average >= t['ok_min'].to_f
      'ok'
    elsif average >= t['bad_min'].to_f
      'bad'
    else
      'superbad'
    end
  end

  def escalated_state(rate_percent)
    t = Setting.get('team_kpi_escalated_thresholds')
    if rate_percent >= t['superbad_min'].to_f
      'superbad'
    elsif rate_percent >= t['bad_min'].to_f
      'bad'
    elsif rate_percent >= t['ok_min'].to_f
      'ok'
    elsif rate_percent >= t['good_min'].to_f
      'good'
    else
      'supergood'
    end
  end
end
