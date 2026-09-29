# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Per-agent breakdown for the "KPI Tim" agent table
# (docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 10). Grouped by ticket owner;
# owner_id 1 (system/nobody) is reported as the "unassigned" row -- except
# FRT, which belongs to the agent who replied first (Scope::FRT_RESPONDER_JOIN,
# Section 21), with % of tickets within their group's/channel's target
# (Section 20).
#
# Period columns (tickets, FRT, CSAT) use the selected window; escalated
# and eskalasi-breach counts are real-time snapshots, like the summary.
# Access to this breakdown is restricted in TeamKpiController (it exposes
# colleagues' performance), on top of the usual group scope.
class Service::Dashboard::TeamKpi::Agents
  UNASSIGNED_ID = 1

  def self.call(...)
    new(...).call
  end

  def initialize(window_days: nil, user: nil, filters: {}, limit: 50)
    @window_days = Service::Dashboard::TeamKpi.window_days(window_days)
    @scope       = Service::Dashboard::TeamKpi::Scope.new(user: user, filters: filters)
    @range       = Service::Dashboard::TeamKpi::Scope.window_range(@window_days)
    @limit       = limit.to_i.clamp(1, 200)
  end

  def call
    handled = @scope.tickets.where(created_at: @range).group(:owner_id).count
    frt     = frt_by_responder
    csat    = csat_by_owner
    escal   = escalated_by_owner
    breach  = breached_by_owner

    owner_ids = (handled.keys | frt.keys | csat.keys | escal.keys | breach.keys).compact
    users     = User.where(id: owner_ids).pluck(:id, :firstname, :lastname, :email).to_h { |id, f, l, e| [id, { name: "#{f} #{l}".strip, email: e.presence }] }

    rows = owner_ids.map do |owner_id|
      frt_median, frt_mean, frt_count, frt_met = frt[owner_id]
      csat_avg, csat_count            = csat[owner_id]
      {
        owner_id:           owner_id,
        name:               owner_id == UNASSIGNED_ID ? nil : users.dig(owner_id, :name),
        # stable key for matching agents in the consuming app's own user table
        email:              owner_id == UNASSIGNED_ID ? nil : users.dig(owner_id, :email),
        unassigned:         owner_id == UNASSIGNED_ID,
        tickets:            handled[owner_id].to_i,
        frt_median_minutes: frt_median,
        frt_mean_minutes:   frt_mean,
        frt_count:          frt_count.to_i,
        frt_target_met_count:   frt_met.to_i,
        frt_target_met_percent: frt_count.to_i.zero? ? nil : (frt_met.to_f / frt_count * 100).round(1),
        csat_average:       csat_avg,
        csat_count:         csat_count.to_i,
        escalated:          escal[owner_id].to_i,
        eskalasi_breached:  breach[owner_id].to_i,
      }
    end
    rows.sort_by! { |row| [row[:unassigned] ? 1 : 0, -row[:tickets], -row[:escalated], row[:name].to_s] }

    {
      window_days: @window_days,
      period:      { from: @range.begin.iso8601, to: @range.end.iso8601 },
      total:       rows.size,
      agents:      rows.first(@limit),
    }
  end

  private

  # Tiket tanpa balasan Agent publik (seharusnya tidak ada: first_response_at
  # terisi) masuk baris "Belum ditugaskan".
  def frt_by_responder
    scope   = Service::Dashboard::TeamKpi::Scope
    minutes = scope.frt_minutes_sql
    target  = scope.frt_target_sql
    @scope.frt_tickets(@range)
      .joins(scope::FRT_RESPONDER_JOIN)
      .joins(scope::FRT_TARGET_JOIN)
      .group(Arel.sql("COALESCE(frt_resp.responder_id, #{UNASSIGNED_ID})"))
      .pluck(Arel.sql("COALESCE(frt_resp.responder_id, #{UNASSIGNED_ID})"), Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY #{minutes})"),
             Arel.sql("AVG(#{minutes})"), Arel.sql('COUNT(*)'), Arel.sql("COUNT(*) FILTER (WHERE #{minutes} <= #{target})"))
      .to_h { |id, median, mean, count, met| [id, [median&.to_f&.round(1), mean&.to_f&.round(1), count, met]] }
  end

  def csat_by_owner
    @scope.tickets
      .where(csat_submitted_at: @range)
      .where.not(csat_score: nil)
      .group(:owner_id)
      .pluck(:owner_id, Arel.sql('AVG(csat_score)'), Arel.sql('COUNT(*)'))
      .to_h { |owner_id, avg, count| [owner_id, [avg&.to_f&.round(2), count]] }
  end

  def escalated_by_owner
    @scope.tickets
      .where.not(state_id: Ticket::State.by_category(:closed))
      .where.not(escalation_at: nil)
      .where(escalation_at: ..Time.zone.now)
      .group(:owner_id)
      .count
  end

  def breached_by_owner
    state = Ticket::State.find_by(name: 'eskalasi')
    return {} if !state

    @scope.tickets
      .where(state_id: state.id)
      .where.not(escalation_deadline_at: nil)
      .where(escalation_deadline_at: ..Time.zone.now)
      .group(:owner_id)
      .count
  end
end
