class App.DashboardTeamKpi extends App.Controller
  constructor: ->
    super
    @load()

  load: =>
    @startLoading()
    @ajax(
      id:   'team_kpi'
      type: 'GET'
      url:  "#{@apiPath}/team_kpi"
      processData: true
      success: (data) =>
        @stopLoading()
        @render(data)
      error: =>
        @stopLoading()
        @render({})
    )

  render: (data = {}) =>
    data.frt_display  = if data.frt_median_minutes? then "#{data.frt_median_minutes} #{__('min')}" else '-'
    data.csat_display  = if data.csat_average? then "#{data.csat_average} / 5" else '-'
    data.ticket_new       ?= 0
    data.ticket_open       ?= 0
    data.ticket_escalated  ?= 0
    data.window_days      ?= 7

    @html App.view('dashboard/team_kpi')(data)
