# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Admin-editable settings for the "KPI Tim" Dashboard tab (see
# docs/DESIGN_TEAM_KPI_DASHBOARD.md), all under area 'TeamKpi::Base' --
# viewable/editable via Admin > Settings > SISKA > KPI Tim (see
# app/assets/javascripts/app/controllers/_manage/siska_settings.coffee).
#
#   bundle exec rails runner script/create_team_kpi_settings.rb RAILS_ENV=production
#
# create_if_not_exists is a no-op if a Setting already exists -- to
# change values afterwards, either use the Admin UI above, or:
#
#   Setting.set('team_kpi_auto_refresh_seconds', 300)
#   Setting.set('team_kpi_default_window_days', 7)
#   Setting.set('team_kpi_max_window_days', 730)
#   Setting.set('team_kpi_frt_thresholds', { 'supergood_max' => 60, 'good_max' => 240, 'ok_max' => 480, 'bad_max' => 1440 })
#   Setting.set('team_kpi_csat_thresholds', { 'supergood_min' => 4.5, 'good_min' => 4.0, 'ok_min' => 3.0, 'bad_min' => 2.0 })
#   Setting.set('team_kpi_escalated_thresholds', { 'good_min' => 20, 'ok_min' => 40, 'bad_min' => 65, 'superbad_min' => 90 })

# frontend: true so the value reaches the legacy frontend via
# App.Config.get('team_kpi_auto_refresh_seconds') (same mechanism as e.g.
# product_logo -- see _application_controller/_base.coffee).
Setting.create_if_not_exists(
  title:       'KPI Tim Auto-Refresh Interval (seconds)',
  name:        'team_kpi_auto_refresh_seconds',
  area:        'TeamKpi::Base',
  description: 'How often (in seconds) the "KPI Tim" Dashboard tab automatically refreshes its data while visible. Set to 0 to disable auto-refresh entirely (manual reload / range-filter change only).',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'team_kpi_auto_refresh_seconds',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  state:       300, # 5 minutes
  preferences: { permission: ['admin.system'] },
  frontend:    true,
)

# frontend: true so team_kpi.coffee's range dropdown can default to the
# same value the backend (Service::Dashboard::TeamKpi) uses, instead of
# a separately hardcoded constant that could silently drift out of sync.
Setting.create_if_not_exists(
  title:       'KPI Tim Default Window (days)',
  name:        'team_kpi_default_window_days',
  area:        'TeamKpi::Base',
  description: 'Default rolling-window size (in days) for FRT/CSAT on the "KPI Tim" Dashboard tab, used when no range filter has been picked yet.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'team_kpi_default_window_days',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  state:       7,
  preferences: { permission: ['admin.system'] },
  frontend:    true,
)

Setting.create_if_not_exists(
  title:       'KPI Tim Max Window (days)',
  name:        'team_kpi_max_window_days',
  area:        'TeamKpi::Base',
  description: 'Upper bound (in days) the "days" API parameter is clamped to -- see Service::Dashboard::TeamKpi#initialize. Default 730 (2 years), per the original retroactive-history requirement.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'team_kpi_max_window_days',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  state:       730,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

# Thresholds mirror the native "My Stats" widgets' supergood/good/ok/bad/
# superbad color convention -- see Service::Dashboard::TeamKpi for the
# calibration rationale (adapted from lib/stats/ticket_waiting_time.rb).
# minutes, lower = better.
Setting.create_if_not_exists(
  title:       'KPI Tim FRT Thresholds (minutes)',
  name:        'team_kpi_frt_thresholds',
  area:        'TeamKpi::Base',
  description: 'First Response Time median (minutes) cutoffs for supergood/good/ok/bad -- anything above bad_max is superbad. Lower FRT is better.',
  options:     {
    form: [
      { display: 'Supergood max (menit)', null: true, name: 'supergood_max', tag: 'input', type: 'number' },
      { display: 'Good max (menit)',      null: true, name: 'good_max',      tag: 'input', type: 'number' },
      { display: 'Ok max (menit)',        null: true, name: 'ok_max',        tag: 'input', type: 'number' },
      { display: 'Bad max (menit)',       null: true, name: 'bad_max',       tag: 'input', type: 'number' },
    ],
  },
  state:       { 'supergood_max' => 60, 'good_max' => 240, 'ok_max' => 480, 'bad_max' => 1440 },
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

# 1-5 scale, higher = better.
Setting.create_if_not_exists(
  title:       'KPI Tim CSAT Thresholds (1-5)',
  name:        'team_kpi_csat_thresholds',
  area:        'TeamKpi::Base',
  description: 'CSAT average (1-5) cutoffs for supergood/good/ok/bad -- anything below bad_min is superbad. Higher CSAT is better.',
  options:     {
    form: [
      { display: 'Supergood min', null: true, name: 'supergood_min', tag: 'input', type: 'number' },
      { display: 'Good min',      null: true, name: 'good_min',      tag: 'input', type: 'number' },
      { display: 'Ok min',        null: true, name: 'ok_min',        tag: 'input', type: 'number' },
      { display: 'Bad min',       null: true, name: 'bad_min',       tag: 'input', type: 'number' },
    ],
  },
  state:       { 'supergood_min' => 4.5, 'good_min' => 4.0, 'ok_min' => 3.0, 'bad_min' => 2.0 },
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

# Percent of (New + Open) tickets that are escalated -- mirrors
# lib/stats/ticket_reopen.rb's rate bucket exactly. Higher rate = worse
# (inverted polarity vs. FRT/CSAT above), so the field names/order run
# good -> superbad instead of supergood -> bad.
Setting.create_if_not_exists(
  title:       'KPI Tim Escalated Rate Thresholds (%)',
  name:        'team_kpi_escalated_thresholds',
  area:        'TeamKpi::Base',
  description: 'Escalated ticket rate (%, of New+Open) cutoffs for good/ok/bad/superbad -- anything below good_min is supergood. Higher rate is worse.',
  options:     {
    form: [
      { display: 'Good min (%)',     null: true, name: 'good_min',     tag: 'input', type: 'number' },
      { display: 'Ok min (%)',       null: true, name: 'ok_min',       tag: 'input', type: 'number' },
      { display: 'Bad min (%)',      null: true, name: 'bad_min',      tag: 'input', type: 'number' },
      { display: 'Superbad min (%)', null: true, name: 'superbad_min', tag: 'input', type: 'number' },
    ],
  },
  state:       { 'good_min' => 20, 'ok_min' => 40, 'bad_min' => 65, 'superbad_min' => 90 },
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

# Percent of tickets currently in the "eskalasi" state that are past their
# escalation_deadline_at (see docs/DESIGN_ESCALATION_STATUS.md,
# Service::Escalation::CalculateDeadlines). Deliberately separate from
# team_kpi_escalated_thresholds above -- that one tracks native SLA
# breaches (Ticket#escalation_at), this one tracks the custom post-
# Eskalasi budget clock. Same rate-bucket shape/polarity as Escalated
# (higher rate is worse).
Setting.create_if_not_exists(
  title:       'KPI Tim Eskalasi Breach Rate Thresholds (%)',
  name:        'team_kpi_eskalasi_breach_thresholds',
  area:        'TeamKpi::Base',
  description: 'Percent of tickets in "eskalasi" state past their escalation_deadline_at, cutoffs for good/ok/bad/superbad -- anything below good_min is supergood. Higher rate is worse.',
  options:     {
    form: [
      { display: 'Good min (%)',     null: true, name: 'good_min',     tag: 'input', type: 'number' },
      { display: 'Ok min (%)',       null: true, name: 'ok_min',       tag: 'input', type: 'number' },
      { display: 'Bad min (%)',      null: true, name: 'bad_min',      tag: 'input', type: 'number' },
      { display: 'Superbad min (%)', null: true, name: 'superbad_min', tag: 'input', type: 'number' },
    ],
  },
  state:       { 'good_min' => 20, 'ok_min' => 40, 'bad_min' => 65, 'superbad_min' => 90 },
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts 'Done.'
