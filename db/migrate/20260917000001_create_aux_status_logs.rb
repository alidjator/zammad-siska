# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). Lihat
# docs/DESIGN_AUX_STATUS.md Section 5.6 untuk alasan pakai tabel dedicated
# (bukan History bawaan): agregasi "total durasi status X per hari" jauh
# lebih mudah dengan started_at/ended_at eksplisit.
class CreateAuxStatusLogs < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :aux_status_logs, id: :integer do |t|
      t.references :user, null: false, foreign_key: { to_table: :users }, type: :integer
      t.string     :status, limit: 255, null: false
      t.references :changed_by, null: true, foreign_key: { to_table: :users }, type: :integer
      t.timestamp  :started_at, limit: 3, null: false
      t.timestamp  :ended_at, limit: 3, null: true

      t.timestamps limit: 3

      t.index %i[user_id ended_at]
    end
  end
end
