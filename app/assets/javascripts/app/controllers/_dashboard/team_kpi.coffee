class App.DashboardTeamKpi extends App.Controller
  events:
    'change .js-kpi-range': 'onRangeChange'

  # value = days, keep in sync with team_kpi.jst.eco options
  DEFAULT_RANGE: 7

  constructor: ->
    super
    @selectedRange = @DEFAULT_RANGE
    @load()

  onRangeChange: (e) =>
    @selectedRange = parseInt($(e.target).val(), 10)
    @load()

  load: =>
    @startLoading()
    @ajax(
      id:   'team_kpi'
      type: 'GET'
      url:  "#{@apiPath}/team_kpi"
      data:
        days: @selectedRange
      processData: true
      success: (data) =>
        @stopLoading()
        @render(data)
      error: =>
        @stopLoading()
        @render({ window_days: @selectedRange })
    )

  render: (data = {}) =>
    data.frt_display      = if data.frt_median_minutes? then "#{data.frt_median_minutes} #{__('min')}" else '-'
    data.csat_display      = if data.csat_average? then "#{data.csat_average} / 5" else '-'
    data.ticket_new         ?= 0
    data.ticket_open         ?= 0
    data.ticket_escalated    ?= 0
    data.window_days        ?= @selectedRange
    data.selectedRange       = @selectedRange

    @html App.view('dashboard/team_kpi')(data)
