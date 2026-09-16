class App.DashboardTeamKpi extends App.Controller
  events:
    'change .js-kpi-range': 'onRangeChange'

  constructor: ->
    super
    # Setting team_kpi_default_window_days (frontend: true, see
    # script/create_team_kpi_settings.rb) is the same default the backend
    # uses (Service::Dashboard::TeamKpi.default_window_days) -- read from
    # App.Config instead of a separately hardcoded constant here, so the
    # two can't silently drift out of sync. 7 is only a last-resort
    # fallback if the config value is somehow missing.
    @selectedRange = parseInt(App.Config.get('team_kpi_default_window_days'), 10) || 7
    @load()
    @startAutoRefresh()

  onRangeChange: (e) =>
    @selectedRange = parseInt($(e.target).val(), 10)
    @load()

  load: (silent = false) =>
    @startLoading() if !silent
    @ajax(
      id:   'team_kpi'
      type: 'GET'
      url:  "#{@apiPath}/team_kpi"
      data:
        days: @selectedRange
      processData: true
      success: (data) =>
        @stopLoading() if !silent
        @render(data)
      error: =>
        @stopLoading() if !silent
        @render({ window_days: @selectedRange }) if !silent
    )

  # Configurable via Setting team_kpi_auto_refresh_seconds (default 300s /
  # 5 minutes, admin-editable, 0 disables it -- see
  # script/create_team_kpi_settings.rb). The timer itself just ticks at a
  # fixed cadence; @maybeAutoRefresh decides on every tick whether to
  # actually fetch, so we don't hit the database when nobody's looking:
  # the browser tab is in the background (document.hidden), or the
  # Dashboard is showing a different sub-tab ("My Stats"/"First Steps" --
  # Dashboard#toggle adds/removes .hidden on @el itself, see
  # dashboard.coffee, so @el.hasClass('hidden') is exactly "is KPI Tim
  # the active sub-tab right now").
  startAutoRefresh: =>
    seconds = parseInt(App.Config.get('team_kpi_auto_refresh_seconds'), 10)
    return if !seconds || seconds <= 0

    @autoRefreshTimer = setInterval(@maybeAutoRefresh, seconds * 1000)

  maybeAutoRefresh: =>
    return if document.hidden
    return if @el.hasClass('hidden')

    @load(true)

  render: (data = {}) =>
    data.frt_display      = if data.frt_median_minutes? then "#{data.frt_median_minutes} #{__('min')}" else '-'
    data.csat_display      = if data.csat_average? then "#{data.csat_average} / 5" else '-'
    data.ticket_new         ?= 0
    data.ticket_open         ?= 0
    data.ticket_escalated    ?= 0
    data.window_days        ?= @selectedRange
    data.selectedRange       = @selectedRange

    # state (supergood/good/ok/bad/superbad/null) drives the icon+value
    # color via Zammad's own *-color CSS classes -- see team_kpi.rb for
    # the threshold rationale. null (new/open ticket counts) stays
    # uncolored on purpose, same as native's non-performance widgets.
    data.frt_state_class       = if data.frt_state then "#{data.frt_state}-color" else ''
    data.csat_state_class      = if data.csat_state then "#{data.csat_state}-color" else ''
    data.escalated_state_class = if data.escalated_state then "#{data.escalated_state}-color" else ''

    @html App.view('dashboard/team_kpi')(data)
    @$('.js-team-kpi-help').tooltip()
