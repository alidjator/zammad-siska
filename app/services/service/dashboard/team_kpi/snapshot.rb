# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Snapshot per jam angka real-time KPI Tim (docs/DESIGN_TEAM_KPI_DASHBOARD.md
# Section 13) -- dasar tren Rasio Escalated dan delta "vs kemarin, jam sama"
# untuk kartu real-time. Nilai-nilai ini (New/Open/Escalated/Eskalasi)
# adalah kondisi "saat ini" dan tidak tersimpan di mana pun, jadi riwayatnya
# baru ada sejak job ini berjalan.
#
# .capture dijalankan Scheduler "KPI Tim: snapshot per jam" tiap 15 menit
# (script/create_team_kpi_snapshot_scheduler.rb) tapi hanya menulis sekali
# per jam: kalau baris penanda jam ini sudah ada, tidak melakukan apa-apa.
# Per grup (bukan hanya total) supaya pembatasan akses grup tetap berlaku;
# filter prioritas/channel/kategori tidak didukung untuk data snapshot.
# Definisi hitungan = sama persis dengan ringkasan (Service::Dashboard::TeamKpi).
class Service::Dashboard::TeamKpi::Snapshot
  COLUMNS = %i[ticket_new ticket_open ticket_escalated eskalasi_active eskalasi_breached].freeze

  # Snapshot "kemarin, jam sama" boleh meleset sejauh ini (job terlambat,
  # restart) sebelum dianggap tidak ada.
  NEAREST_TOLERANCE = 2.hours

  def self.capture(now: Time.zone.now, force: false)
    hour = now.utc.beginning_of_hour
    return :exists if !force && TeamKpiSnapshot.markers.exists?(captured_at: hour)

    rows = counts_by_group(now)
    total = COLUMNS.index_with { |c| rows.values.sum { |r| r[c] } }
    records = rows.map { |group_id, r| r.merge(group_id: group_id, captured_at: hour, created_at: now) }
    records << total.merge(group_id: TeamKpiSnapshot::MARKER_GROUP_ID, captured_at: hour, created_at: now)

    TeamKpiSnapshot.transaction do
      TeamKpiSnapshot.where(captured_at: hour).delete_all if force
      TeamKpiSnapshot.insert_all(records, unique_by: %i[captured_at group_id])
    end
    purge(now)
    :captured
  end

  # Batas histori = team_kpi_max_window_days (sama dengan data production,
  # lihat Section 10.2) + 2 hari untuk pembanding "kemarin".
  def self.purge(now = Time.zone.now)
    TeamKpiSnapshot.where(captured_at: ...(now - Service::Dashboard::TeamKpi.max_window_days.days - 2.days)).delete_all
  end

  # { group_id => { ticket_new:, ... } }, hanya grup yang punya angka.
  def self.counts_by_group(now)
    state_ids = ->(type) { Ticket::State.joins(:state_type).where(ticket_state_types: { name: type }).pluck(:id) }
    eskalasi  = Ticket::State.find_by(name: 'eskalasi')
    counts = {
      ticket_new:       Ticket.where(state_id: state_ids.call('new')).group(:group_id).count,
      ticket_open:      Ticket.where(state_id: state_ids.call('open')).group(:group_id).count,
      ticket_escalated: Ticket.where.not(state_id: Ticket::State.by_category(:closed)).where.not(escalation_at: nil)
                              .where(escalation_at: ..now).group(:group_id).count,
      eskalasi_active:  eskalasi ? Ticket.where(state_id: eskalasi.id).group(:group_id).count : {},
      eskalasi_breached: if eskalasi
                           Ticket.where(state_id: eskalasi.id).where.not(escalation_deadline_at: nil)
                                 .where(escalation_deadline_at: ..now).group(:group_id).count
                         else
                           {}
                         end,
    }
    group_ids = counts.values.flat_map(&:keys).uniq
    group_ids.index_with { |g| COLUMNS.index_with { |c| counts[c][g].to_i } }
  end

  # Snapshot terdekat ke `at` (maks NEAREST_TOLERANCE), dijumlah untuk grup
  # dalam scope. nil kalau tidak ada.
  def self.nearest(scope, at)
    hour   = at.utc.beginning_of_hour
    marker = TeamKpiSnapshot.markers
      .where(captured_at: (hour - NEAREST_TOLERANCE)..(hour + NEAREST_TOLERANCE))
      .order(Arel.sql(ActiveRecord::Base.sanitize_sql_array(['ABS(EXTRACT(EPOCH FROM (captured_at - ?)))', hour])))
      .first
    return nil if !marker

    rows = rows_in_scope(scope).where(captured_at: marker.captured_at)
    sums = COLUMNS.index_with { |c| rows.sum(c) }
    sums.merge(captured_at: marker.captured_at)
  end

  def self.rows_in_scope(scope)
    rows = TeamKpiSnapshot.groups
    rows = rows.where(group_id: scope.group_ids) if !scope.group_ids.nil?
    rows
  end

  # Snapshot tidak dipisah per prioritas/channel/kategori.
  def self.supported?(scope)
    scope.filters.values_at(:priority_ids, :channels, :categories).all?(&:blank?)
  end

  def self.history_since
    TeamKpiSnapshot.markers.minimum(:captured_at)
  end
end
