# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Snapshot per jam angka real-time KPI Tim per grup -- lihat
# Service::Dashboard::TeamKpi::Snapshot dan docs/DESIGN_TEAM_KPI_DASHBOARD.md
# Section 13. ActiveRecord::Base biasa (bukan ApplicationModel): baris data
# statistik internal, tanpa created_by/updated_by, cache, search index atau
# event -- ditulis massal lewat upsert_all.
class TeamKpiSnapshot < ActiveRecord::Base
  # group_id penanda (total seluruh sistem, menandai jam yang sudah diambil)
  MARKER_GROUP_ID = 0

  scope :markers, -> { where(group_id: MARKER_GROUP_ID) }
  scope :groups,  -> { where.not(group_id: MARKER_GROUP_ID) }
end
