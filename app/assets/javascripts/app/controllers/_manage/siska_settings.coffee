# Admin UI tab for the custom Settings this project added (CSAT --
# docs/DESIGN_FEEDBACK_RATING.md -- KPI Tim --
# docs/DESIGN_TEAM_KPI_DASHBOARD.md -- Eskalasi --
# docs/DESIGN_ESCALATION_STATUS.md -- Reporting --
# docs/DESIGN_REPORTING_FRT.md -- AUX Status --
# docs/DESIGN_AUX_STATUS.md) PLUS one native Zammad Setting exposed here
# because it had no Admin UI anywhere else at all --
# `ui_ticket_overview_ticket_limit` ("Overview" tab below,
# script/expose_ticket_overview_limit_setting.rb): the max tickets an
# Overview query returns, native/already fully functional, just missing
# `options.form` in its original seed. NOTE: that Setting's own
# permission is `admin.overview`, narrower than this whole tab's
# `admin.system` gate below -- an admin who has `admin.overview` but NOT
# `admin.system` still can't reach it here; acceptable for now since in
# practice the people managing Settings on this deployment already have
# `admin.system`, but worth a separate exposure point later if that
# stops being true. Mirrors the exact pattern used by
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
      { name: __('CSAT'),      'target': 'csat',      controller: App.SettingsArea, params: { area: 'CSAT::Base' } }
      { name: __('KPI Tim'),   'target': 'team_kpi',  controller: App.SettingsArea, params: { area: 'TeamKpi::Base' } }
      { name: __('Eskalasi'), 'target': 'escalation', controller: App.SettingsArea, params: { area: 'Escalation::Base' } }
      { name: __('Reporting'), 'target': 'reporting', controller: App.SettingsArea, params: { area: 'Reporting::Base' } }
      { name: __('AUX Status'), 'target': 'aux_status', controller: App.SettingsArea, params: { area: 'SISKA::AuxStatus' } }
      { name: __('Overview'), 'target': 'overview', controller: App.SettingsArea, params: { area: 'UI::TicketOverview::TicketLimit' } }
    ]
    @render()

App.Config.set('SettingSiska', { prio: 1250, parent: '#settings', name: __('SISKA'), target: '#settings/siska', controller: SiskaSettings, permission: ['admin.system'] }, 'NavBarAdmin')
