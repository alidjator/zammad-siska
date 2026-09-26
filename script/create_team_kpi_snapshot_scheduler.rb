# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Registers the job that stores an hourly snapshot of the KPI Tim real-time
# numbers (New/Open/Escalated/Eskalasi per group) -- see
# docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 13 and
# app/services/service/dashboard/team_kpi/snapshot.rb.
#
# Runs every 15 minutes but writes at most once per hour (skips when the
# current hour is already captured), so a late or restarted scheduler still
# fills every hour. Only writes internal statistics, sends nothing -- safe
# to be active from the start. Needs the team_kpi_snapshots table
# (db/migrate/20260927000001_create_team_kpi_snapshots.rb) first.
#
#   bundle exec rails runner script/create_team_kpi_snapshot_scheduler.rb

Scheduler.create_if_not_exists(
  name:          'KPI Tim: snapshot per jam',
  method:        'Service::Dashboard::TeamKpi::Snapshot.capture',
  period:        15.minutes,
  prio:          2,
  active:        true,
  created_by_id: 1,
  updated_by_id: 1,
)

puts 'Done.'
