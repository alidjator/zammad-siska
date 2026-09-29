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
#   - Eskalasi breach: reuses the exact same rate-bucket pattern as
#     Escalated (>=20/40/65/90%), but as percent-of-tickets-in-Eskalasi
#     that are past `escalation_deadline_at` -- see
#     docs/DESIGN_ESCALATION_STATUS.md (gap analysis item No. 3/12). This
#     is deliberately separate from `escalated_state` above: that one is
#     native-SLA-based (Ticket#escalation_at, ticket_escalated), this one
#     is the custom post-Eskalasi budget clock
#     (Ticket#escalation_deadline_at, computed by
#     Service::Escalation::CalculateDeadlines) -- a ticket can breach one
#     without the other.
# Fase 2 (BI): every query runs on Service::Dashboard::TeamKpi::Scope --
# limited to the requesting user's readable groups plus optional filters
# -- and period metrics come with a sample size and, per the dashboard's
# comparison rule, the same metrics for the comparison period. Trend,
# heatmap and per-agent breakdowns live in TeamKpi::Trend / ::Heatmap /
# ::Agents.
# See docs/DESIGN_TEAM_KPI_DASHBOARD.md for the full rationale and the
# calibration data behind these thresholds.
class Service::Dashboard::TeamKpi
  # Same buckets as native lib/stats/ticket_reopen.rb (rate, higher is worse).
  REOPEN_BUCKETS = { 'good_min' => 20, 'ok_min' => 40, 'bad_min' => 65, 'superbad_min' => 90 }.freeze

  # Age buckets for tickets that are still open, in days: [key, from, to).
  BACKLOG_BUCKETS = [
    ['lt_1d',   0,  1],
    ['d1_3',    1,  3],
    ['d3_7',    3,  7],
    ['d7_30',   7,  30],
    ['gte_30d', 30, nil],
  ].freeze

  # include_agents: true hanya untuk report/admin (TeamKpiController) --
  # menambah agents_active_count untuk badge tab "Per agent".
  def self.call(window_days: default_window_days, user: nil, filters: {}, compare: 'auto', include_agents: false)
    new(window_days, user: user, filters: filters, compare: compare, include_agents: include_agents).call
  end

  def self.default_window_days
    Setting.get('team_kpi_default_window_days').to_i
  end

  def self.max_window_days
    Setting.get('team_kpi_max_window_days').to_i
  end

  def self.window_days(value)
    (value.presence || default_window_days).to_i.clamp(1, max_window_days)
  end

  def initialize(window_days, user: nil, filters: {}, compare: 'auto', include_agents: false)
    @include_agents = include_agents
    @window_days = self.class.window_days(window_days)
    @scope       = Service::Dashboard::TeamKpi::Scope.new(user: user, filters: filters)
    @range       = Service::Dashboard::TeamKpi::Scope.window_range(@window_days)
    @comparison  = Service::Dashboard::TeamKpi::Scope.comparison(@range, @window_days, mode: compare)
  end

  def call
    period      = period_metrics(@range)
    new_count   = ticket_count_by_state_type('new')
    open_count  = ticket_count_by_state_type('open')
    escalated   = ticket_escalated_count
    escalation_rate = escalation_rate_percent(escalated, new_count, open_count)
    eskalasi_active   = eskalasi_active_count
    eskalasi_breached = eskalasi_breached_count
    eskalasi_breach_rate = eskalasi_breach_rate_percent(eskalasi_breached, eskalasi_active)

    {
      frt_median_minutes:     period[:frt_median_minutes],
      frt_mean_minutes:       period[:frt_mean_minutes],
      frt_count:              period[:frt_count],
      frt_state:              frt_state(period[:frt_median_minutes]),
      frt_target_met_count:   period[:frt_target_met_count],
      frt_target_met_percent: period[:frt_target_met_percent],
      frt_target_minutes:     period[:frt_target_minutes],
      frt_target_basis:       Service::Dashboard::TeamKpi::Scope.frt_target_basis,
      frt_time_basis:         Service::Dashboard::TeamKpi::Scope.frt_time_basis,
      frt_calendar_median_minutes: period[:frt_calendar_median_minutes],
      frt_target_state:       frt_target_state(period[:frt_target_met_percent]),
      csat_average:           period[:csat_average],
      csat_count:             period[:csat_count],
      csat_state:             csat_state(period[:csat_average]),
      resolution_median_minutes: period[:resolution_median_minutes],
      resolution_mean_minutes:   period[:resolution_mean_minutes],
      resolution_count:          period[:resolution_count],
      reopen_count:           period[:reopen_count],
      reopen_closed_count:    period[:reopen_closed_count],
      reopen_rate_percent:    period[:reopen_rate_percent],
      reopen_state:           rate_state(period[:reopen_rate_percent], REOPEN_BUCKETS),
      sla_total:              period[:sla_total],
      sla_within:             period[:sla_within],
      sla_late:               period[:sla_late],
      sla_within_percent:     period[:sla_within_percent],
      sla_late_median_minutes: period[:sla_late_median_minutes],
      sla_by_priority:        sla_by_priority(@range),
      ticket_new:             new_count,
      ticket_open:            open_count,
      ticket_escalated:       escalated,
      escalation_rate_percent: escalation_rate,
      escalated_state:        escalated_state(escalation_rate),
      eskalasi_active:            eskalasi_active,
      eskalasi_breached:          eskalasi_breached,
      eskalasi_breach_rate_percent: eskalasi_breach_rate,
      eskalasi_breach_state:      eskalasi_breach_state(eskalasi_breach_rate),
      backlog_aging:          backlog_aging,
      realtime_comparison:    realtime_comparison(new_count, open_count, escalated, eskalasi_active, eskalasi_breached),
      window_days:            @window_days,
      period:                 range_json(@range),
      comparison:             comparison_json,
      thresholds:             thresholds,
      filters:                @scope.filters,
      group_ids_count:        @scope.group_ids&.size,
      generated_at:           Time.zone.now.iso8601,
    }.tap { |result| result[:agents_active_count] = agents_active_count if @include_agents }
  end

  private

  def tickets
    @scope.tickets
  end

  # Real-time numbers ~24 hours ago from the hourly snapshots (Section 13),
  # for the "vs kemarin, jam sama" delta. available: false with a reason
  # when there is nothing to compare: filters the snapshots are not split
  # by, or no snapshot around that time yet (history starts when the job
  # started).
  def realtime_comparison(new_count, open_count, escalated, eskalasi_active, eskalasi_breached)
    snapshot = Service::Dashboard::TeamKpi::Snapshot
    return { available: false, reason: 'filters' } if !snapshot.supported?(@scope)

    at   = Time.zone.now - 24.hours
    past = snapshot.nearest(@scope, at)
    if !past
      since = snapshot.history_since
      return { available: false, reason: since ? 'no_snapshot' : 'no_history', history_since: since&.iso8601 }
    end

    {
      available:                    true,
      captured_at:                  past[:captured_at].iso8601,
      ticket_new:                   past[:ticket_new],
      ticket_open:                  past[:ticket_open],
      ticket_escalated:             past[:ticket_escalated],
      escalation_rate_percent:      escalation_rate_percent(past[:ticket_escalated], past[:ticket_new], past[:ticket_open]),
      eskalasi_active:              past[:eskalasi_active],
      eskalasi_breached:            past[:eskalasi_breached],
      eskalasi_breach_rate_percent: eskalasi_breach_rate_percent(past[:eskalasi_breached], past[:eskalasi_active]),
    }
  end

  # The cutoffs behind every *_state, so a UI can label its scale
  # ("Sangat baik <= 60 min") from the same Settings instead of copying
  # the numbers. frt/csat: 4 cutoffs for supergood..bad (lower/higher is
  # better); rate metrics: good_min..superbad_min (higher is worse).
  def thresholds
    {
      frt:             Setting.get('team_kpi_frt_thresholds'),
      frt_target_met:  Setting.get('team_kpi_frt_target_met_thresholds'),
      csat:            Setting.get('team_kpi_csat_thresholds'),
      escalated:       Setting.get('team_kpi_escalated_thresholds'),
      eskalasi_breach: Setting.get('team_kpi_eskalasi_breach_thresholds'),
      reopen:          REOPEN_BUCKETS,
    }
  end

  def range_json(range)
    { from: range.begin.iso8601, to: range.end.iso8601 }
  end

  def comparison_json
    return nil if !@comparison

    range_json(@comparison[:range]).merge(mode: @comparison[:mode]).merge(period_metrics(@comparison[:range]))
  end

  # Everything that depends on the selected period (so it has a
  # comparison-period counterpart). Real-time snapshots are not here.
  def period_metrics(range)
    frt_median, frt_mean, frt_count, frt_met, target_min, target_max, frt_cal_median = frt(range)
    csat_avg, csat_count            = csat(range)
    res_median, res_mean, res_count = resolution(range)
    reopen_count, closed_count      = reopen(range)
    sla                             = sla_totals(range)

    {
      frt_median_minutes:        frt_median,
      frt_mean_minutes:          frt_mean,
      frt_count:                 frt_count,
      frt_target_met_count:      frt_met,
      frt_target_met_percent:    frt_count.zero? ? nil : (frt_met.to_f / frt_count * 100).round(1),
      # satu target untuk seluruh populasi (menit), atau nil kalau campuran
      frt_target_minutes:        target_min && target_min == target_max ? round_or_nil(target_min, 1) : nil,
      frt_calendar_median_minutes: frt_cal_median,
      csat_average:              csat_avg,
      csat_count:                csat_count,
      resolution_median_minutes: res_median,
      resolution_mean_minutes:   res_mean,
      resolution_count:          res_count,
      reopen_count:              reopen_count,
      reopen_closed_count:       closed_count,
      reopen_rate_percent:       closed_count.zero? ? nil : (reopen_count.to_f / closed_count * 100).round(1),
      sla_total:                 sla[:total],
      sla_within:                sla[:within],
      sla_late:                  sla[:late],
      sla_within_percent:        sla[:within_percent],
      sla_late_median_minutes:   sla[:late_median_minutes],
    }
  end

  # Population: Scope#frt_tickets (customer-initiated tickets only, live
  # chat measured from the start of the chat session). Median
  # is the headline, mean on the same population flags a long tail of
  # slow outliers the median alone hides (docs/DESIGN_REPORTING_FRT.md s.3).
  #
  # Target (Section 20): tiap tiket dinilai dengan target grup/kanalnya
  # sendiri; met = jumlah tiket dengan FRT <= targetnya. target_min/max
  # sama = satu target berlaku untuk seluruh populasi (mis. filter 1 grup).
  def frt(range)
    # menit sesuai dasar waktu (Section 22); median jam kalender ikut sebagai
    # konteks pengalaman customer
    minutes  = Service::Dashboard::TeamKpi::Scope.frt_minutes_sql
    calendar = Service::Dashboard::TeamKpi::Scope::FRT_MINUTES_SQL
    target   = Service::Dashboard::TeamKpi::Scope.frt_target_sql
    median, mean, count, met, target_min, target_max, cal_median = @scope.frt_tickets(range)
      .joins(Service::Dashboard::TeamKpi::Scope::FRT_TARGET_JOIN)
      .pick(Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY #{minutes})"), Arel.sql("AVG(#{minutes})"), Arel.sql('COUNT(*)'),
            Arel.sql("COUNT(*) FILTER (WHERE #{minutes} <= #{target})"), Arel.sql("MIN(#{target})"), Arel.sql("MAX(#{target})"),
            Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY #{calendar})"))

    [round_or_nil(median, 1), round_or_nil(mean, 1), count.to_i, met.to_i, target_min&.to_f, target_max&.to_f, round_or_nil(cal_median, 1)]
  end

  def csat(range)
    average, count = tickets
      .where(csat_submitted_at: range)
      .where.not(csat_score: nil)
      .pick(Arel.sql('AVG(csat_score)'), Arel.sql('COUNT(*)'))

    [round_or_nil(average, 2), count.to_i]
  end

  # Created -> first close, for tickets closed in the period.
  def resolution(range)
    minutes = 'EXTRACT(EPOCH FROM (close_at - created_at)) / 60'
    median, mean, count = tickets
      .where(close_at: range)
      .where('close_at >= created_at')
      .pick(Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY #{minutes})"), Arel.sql("AVG(#{minutes})"), Arel.sql('COUNT(*)'))

    [round_or_nil(median, 1), round_or_nil(mean, 1), count.to_i]
  end

  # Team version of native "Reopening rate" (lib/stats/ticket_reopen.rb):
  # reopen events logged in StatsStore during the period, for tickets in
  # scope, over tickets closed in the period.
  def reopen(range)
    ticket_ids = StatsStore
      .where(key: 'ticket:reopen', created_at: range)
      .pluck(:data)
      .filter_map { |data| data.is_a?(Hash) ? data['ticket_id'] || data[:ticket_id] : nil }
      .uniq

    reopened = ticket_ids.empty? ? 0 : tickets.where(id: ticket_ids).count
    [reopened, tickets.where(close_at: range).count]
  end

  # Solution-time SLA per priority: of the tickets closed in the period
  # that had a close deadline (close_escalation_at), how many closed on
  # time. First-response SLA is not configured on this system (no ticket
  # has first_response_escalation_at), so it is not used here.
  SLA_WITHIN = 'SUM(CASE WHEN close_at <= close_escalation_at THEN 1 ELSE 0 END)'.freeze
  # How late the late ones were (minutes past the deadline), median.
  SLA_LATE_MEDIAN = 'percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (close_at - close_escalation_at)) / 60) ' \
                    'FILTER (WHERE close_at > close_escalation_at)'.freeze

  def sla_tickets(range)
    tickets.where(close_at: range).where.not(close_escalation_at: nil)
  end

  # All priorities together -- the headline of the SLA card, also computed
  # for the comparison period (period_metrics) so it gets a delta.
  def sla_totals(range)
    total, within, late_median = sla_tickets(range).pick(Arel.sql('COUNT(*)'), Arel.sql(SLA_WITHIN), Arel.sql(SLA_LATE_MEDIAN))
    total  = total.to_i
    within = within.to_i
    {
      total:               total,
      within:              within,
      late:                total - within,
      within_percent:      total.zero? ? nil : (within.to_f / total * 100).round(1),
      late_median_minutes: round_or_nil(late_median, 1),
    }
  end

  def sla_by_priority(range)
    rows = sla_tickets(range)
      .group(:priority_id)
      .pluck(:priority_id, Arel.sql('COUNT(*)'), Arel.sql(SLA_WITHIN), Arel.sql(SLA_LATE_MEDIAN))
    names = Ticket::Priority.where(id: rows.map(&:first)).pluck(:id, :name).to_h

    rows.sort_by(&:first).reverse.map do |priority_id, total, ok, late_median|
      {
        priority_id:         priority_id,
        priority:            names[priority_id],
        total:               total.to_i,
        within_sla:          ok.to_i,
        late:                total.to_i - ok.to_i,
        within_percent:      total.to_i.zero? ? nil : (ok.to_f / total * 100).round(1),
        late_median_minutes: round_or_nil(late_median, 1),
      }
    end
  end

  # Real-time: tickets still open (not closed/merged) by age.
  def backlog_aging
    now   = Time.zone.now
    scope = tickets.where.not(state_id: Ticket::State.by_category(:closed).pluck(:id) + Ticket::State.by_category(:merged).pluck(:id))

    BACKLOG_BUCKETS.map do |key, from_days, to_days|
      relation = scope.where(created_at: ..(now - from_days.days))
      relation = relation.where('created_at > ?', now - to_days.days) if to_days
      { bucket: key, from_days: from_days, to_days: to_days, count: relation.count }
    end
  end

  def round_or_nil(value, digits)
    value.nil? ? nil : value.to_f.round(digits)
  end

  # Ticket::State.by_category(:open) lumps together new/open/pending
  # reminder/pending action -- we want "new" and "open" as distinct
  # buckets, so query by exact state_type name instead.
  def ticket_count_by_state_type(state_type_name)
    state_ids = Ticket::State.joins(:state_type).where(ticket_state_types: { name: state_type_name }).pluck(:id)
    tickets.where(state_id: state_ids).count
  end

  # Jumlah agent yang muncul di tabel agent (/team_kpi/agents, filter di
  # team_kpi.coffee agentsView): pemilik tiket yang punya tiket dibuat di
  # periode, FRT di periode, atau tiket escalated sekarang -- tanpa owner 1
  # ("Belum ditugaskan", bukan agent). Cukup DISTINCT owner_id, jauh lebih
  # ringan dari rekap per agent lengkap, jadi badge bisa tampil tanpa
  # memuat tabelnya.
  def agents_active_count
    ids  = tickets.where(created_at: @range).distinct.pluck(:owner_id)
    ids |= @scope.frt_tickets(@range).joins(Service::Dashboard::TeamKpi::Scope::FRT_RESPONDER_JOIN).distinct.pluck(Arel.sql('frt_resp.responder_id')) # Section 21
    ids |= tickets
      .where.not(state_id: Ticket::State.by_category(:closed))
      .where.not(escalation_at: nil)
      .where(escalation_at: ..Time.zone.now)
      .distinct.pluck(:owner_id)
    (ids.compact - [Service::Dashboard::TeamKpi::Agents::UNASSIGNED_ID]).size
  end

  def ticket_escalated_count
    tickets
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

  def eskalasi_active_count
    tickets.where(state_id: eskalasi_state_id).count
  end

  def eskalasi_breached_count
    tickets
      .where(state_id: eskalasi_state_id)
      .where.not(escalation_deadline_at: nil)
      .where(escalation_deadline_at: ..Time.zone.now)
      .count
  end

  def eskalasi_state_id
    @eskalasi_state_id ||= Ticket::State.find_by!(name: 'eskalasi').id
  end

  def eskalasi_breach_rate_percent(breached, active)
    return 0.0 if active.zero?

    (breached.to_f / active * 100).round(1)
  end

  def rate_state(rate_percent, t)
    return nil if rate_percent.nil?

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

  # % tiket sesuai target FRT (Section 20), makin tinggi makin baik.
  def frt_target_state(percent)
    return nil if percent.nil?

    t = Setting.get('team_kpi_frt_target_met_thresholds')
    return nil if t.blank?

    if percent >= t['supergood_min'].to_f
      'supergood'
    elsif percent >= t['good_min'].to_f
      'good'
    elsif percent >= t['ok_min'].to_f
      'ok'
    elsif percent >= t['bad_min'].to_f
      'bad'
    else
      'superbad'
    end
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

  def eskalasi_breach_state(rate_percent)
    t = Setting.get('team_kpi_eskalasi_breach_thresholds')
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
