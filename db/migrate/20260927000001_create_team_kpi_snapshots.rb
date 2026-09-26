# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# KPI Tim: snapshot per jam angka real-time (New/Open/Escalated/Eskalasi)
# per grup, supaya tren Rasio Escalated dan delta "vs kemarin, jam sama"
# bisa dihitung -- nilai masa lalunya tidak tersimpan di tempat lain.
# Lihat docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 13.
class CreateTeamKpiSnapshots < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :team_kpi_snapshots, id: :integer do |t|
      # awal jam; satu baris per (jam, grup). timestamptz seperti kolom
      # waktu tickets, supaya `captured_at AT TIME ZONE tz` di tren benar.
      t.timestamptz :captured_at, limit: 3, null: false
      # 0 = baris penanda "snapshot jam ini sudah diambil" berisi total
      # seluruh sistem -- membedakan "jam ini semua nol" dari "tidak ada
      # snapshot". Bukan foreign key karena itu.
      t.integer :group_id, null: false
      t.integer :ticket_new, null: false, default: 0
      t.integer :ticket_open, null: false, default: 0
      t.integer :ticket_escalated, null: false, default: 0
      t.integer :eskalasi_active, null: false, default: 0
      t.integer :eskalasi_breached, null: false, default: 0

      t.timestamptz :created_at, limit: 3, null: false

      t.index %i[captured_at group_id], unique: true
      t.index :group_id
    end
  end
end
