# Admin UI tab for the custom Settings this project added (CSAT --
# docs/DESIGN_FEEDBACK_RATING.md -- and KPI Tim --
# docs/DESIGN_TEAM_KPI_DASHBOARD.md). Mirrors the exact pattern used by
# core Zammad's own _manage/branding.coffee and _manage/system.coffee:
# App.SettingsArea already renders a full generic edit form for any
# `area`, driven by each Setting's own `options.form` -- this file's only
# job is to register the nav entry and hand it the right `area` values.
#
# Without this, these Settings have NO UI surface at all: Admin >
# Settings is hard-coded per built-in area (System/Security/Ticket/
# Branding), so a custom area like 'CSAT::Base' or 'TeamKpi::Base' never
# appears in any tab, no matter how an admin clicks around -- confirmed
# by reading the manage controllers before writing this file. Before
# this existed, the only way to view/change these Settings was
# Setting.get/set via Rails console, or the raw /api/v1/settings API.
class SiskaSettings extends App.ControllerTabs
  @requiredPermission: 'admin.system'
  header: __('SISKA')
  constructor: ->
    super

    @title __('SISKA'), true
    @tabs = [
      { name: __('CSAT'),    'target': 'csat',     controller: App.SettingsArea, params: { area: 'CSAT::Base' } }
      { name: __('KPI Tim'), 'target': 'team_kpi', controller: App.SettingsArea, params: { area: 'TeamKpi::Base' } }
    ]
    @render()

App.Config.set('SettingSiska', { prio: 1250, parent: '#settings', name: __('SISKA'), target: '#settings/siska', controller: SiskaSettings, permission: ['admin.system'] }, 'NavBarAdmin')
