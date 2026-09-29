# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Drill-down of a "KPI Tim" card: the tickets behind the number
# (docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 18). Each metric uses exactly
# the population of its card in Service::Dashboard::TeamKpi, within the
# same group access and filters (Scope), so "Lihat 998 tiket" lists 998:
#
#   frt        Scope#frt_tickets in the period, slowest first
#   csat       rated in the period (csat_submitted_at), newest first
#   resolution closed in the period, longest first
#   reopen     reopen events in the period (StatsStore ticket:reopen), newest first
#   escalated  real-time: not closed, SLA (escalation_at) passed, most overdue first
#   breach     real-time: state Eskalasi, escalation_deadline_at passed, most overdue first
#
# `value` is the metric per ticket (minutes, score or a timestamp) and `at`
# the date column that goes with it; the frontend formats both.
class Service::Dashboard::TeamKpi::Tickets
  METRICS = %w[frt csat resolution reopen escalated breach].freeze
  REALTIME = %w[escalated breach].freeze
  MAX_EXPORT = 5000

  def self.call(...)
    new(...).call
  end

  def initialize(metric:, window_days: nil, user: nil, filters: {}, limit: 50)
    raise ArgumentError, "unknown metric #{metric.inspect}" if METRICS.exclude?(metric.to_s)

    @metric      = metric.to_s
    @window_days = Service::Dashboard::TeamKpi.window_days(window_days)
    @scope       = Service::Dashboard::TeamKpi::Scope.new(user: user, filters: filters)
    @range       = Service::Dashboard::TeamKpi::Scope.window_range(@window_days)
    @limit       = limit.to_i.clamp(1, MAX_EXPORT)
  end

  def call
    relation = population
    total    = relation.count(:all)
    rows     = relation.select(*columns).limit(@limit).to_a
    @owner_names = User.where(id: rows.map(&:owner_id).uniq).pluck(:id, :firstname, :lastname)
      .to_h { |id, first, last| [id, "#{first} #{last}".strip] }
    {
      metric:      @metric,
      realtime:    REALTIME.include?(@metric),
      window_days: @window_days,
      total:       total,
      tickets:     rows.map { |row| serialize(row) },
    }.tap { |r| r[:frt_time_basis] = Service::Dashboard::TeamKpi::Scope.frt_time_basis if @metric == 'frt' }
  end

  private

  def columns
    [
      'tickets.id', 'tickets.number', 'tickets.title', 'tickets.group_id', 'tickets.owner_id',
      'tickets.created_at', 'tickets.close_at',
      Arel.sql("#{value_sql} AS kpi_value"), Arel.sql("#{at_sql} AS kpi_at")
    ]
  end

  def population
    case @metric
    when 'frt'
      @scope.frt_tickets(@range).reorder(Arel.sql("#{Service::Dashboard::TeamKpi::Scope.frt_minutes_sql} DESC"))
    when 'csat'
      @scope.tickets.where(csat_submitted_at: @range).where.not(csat_score: nil).reorder(csat_submitted_at: :desc)
    when 'resolution'
      @scope.tickets.where(close_at: @range).where('tickets.close_at >= tickets.created_at').reorder(Arel.sql("#{resolution_sql} DESC"))
    when 'reopen'
      ids = reopen_events.keys
      @scope.tickets.where(id: ids).reorder(Arel.sql(reopen_order_sql(ids)))
    when 'escalated'
      @scope.tickets.where.not(state_id: Ticket::State.by_category(:closed)).where.not(escalation_at: nil)
        .where(escalation_at: ..Time.zone.now).reorder(escalation_at: :asc)
    when 'breach'
      @scope.tickets.where(state_id: Ticket::State.find_by!(name: 'eskalasi').id).where.not(escalation_deadline_at: nil)
        .where(escalation_deadline_at: ..Time.zone.now).reorder(escalation_deadline_at: :asc)
    end
  end

  def resolution_sql
    'EXTRACT(EPOCH FROM (tickets.close_at - tickets.created_at)) / 60'
  end

  def value_sql
    case @metric
    when 'frt'        then Service::Dashboard::TeamKpi::Scope.frt_minutes_sql
    when 'csat'       then 'tickets.csat_score'
    when 'resolution' then resolution_sql
    else                   'NULL'
    end
  end

  def at_sql
    case @metric
    when 'csat'       then 'tickets.csat_submitted_at'
    when 'resolution' then 'tickets.close_at'
    when 'escalated'  then 'tickets.escalation_at'
    when 'breach'     then 'tickets.escalation_deadline_at'
    else                   'tickets.created_at'
    end
  end

  # Same source as TeamKpi#reopen: ticket:reopen events logged in the
  # period; newest event per ticket.
  def reopen_events
    @reopen_events ||= StatsStore.where(key: 'ticket:reopen', created_at: @range).pluck(:data, :created_at)
      .each_with_object({}) do |(data, at), events|
        id = data.is_a?(Hash) ? (data['ticket_id'] || data[:ticket_id]) : nil
        next if !id

        events[id.to_i] = at if !events[id.to_i] || at > events[id.to_i]
      end
  end

  def reopen_order_sql(ids)
    return 'tickets.id DESC' if ids.empty?

    ordered = reopen_events.sort_by { |_, at| -at.to_f }.map(&:first)
    "array_position(ARRAY[#{ordered.map(&:to_i).join(',')}]::bigint[], tickets.id::bigint)"
  end

  def serialize(row)
    at = @metric == 'reopen' ? reopen_events[row.id] : row.kpi_at
    {
      id:         row.id,
      number:     row.number,
      title:      row.title,
      group:      group_names[row.group_id],
      owner:      row.owner_id == Service::Dashboard::TeamKpi::Agents::UNASSIGNED_ID ? nil : @owner_names[row.owner_id],
      created_at: row.created_at&.iso8601,
      close_at:   row.close_at&.iso8601,
      at:         at&.iso8601,
      value:      row.kpi_value.nil? ? nil : row.kpi_value.to_f.round(2),
    }
  end

  def group_names
    @group_names ||= Group.pluck(:id, :name).to_h
  end
end
