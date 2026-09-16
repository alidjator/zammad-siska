# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Admin-editable auto-refresh interval for the "KPI Tim" Dashboard tab (see
# docs/DESIGN_TEAM_KPI_DASHBOARD.md). frontend: true so the value reaches
# the legacy frontend via App.Config.get('team_kpi_auto_refresh_seconds')
# (same mechanism as e.g. product_logo -- see _application_controller/_base.coffee).
#
#   bundle exec rails runner script/create_team_kpi_settings.rb RAILS_ENV=production
#
# create_if_not_exists is a no-op if the Setting already exists -- to
# change the value afterwards, either use Admin > Settings, or:
#
#   Setting.set('team_kpi_auto_refresh_seconds', 300)

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
  preferences: { permission: ['admin.setting_system'] },
  frontend:    true,
)

puts 'Done.'
