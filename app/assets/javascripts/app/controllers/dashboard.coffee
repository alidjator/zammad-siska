class App.Dashboard extends App.Controller
  clueAccess: true
  events:
    'click .tabs .tab': 'toggle'
    'click .js-intro': 'clues'
    'click .js-kpiActivityToggle': 'toggleKpiActivity'
    'click .js-kpiActivityClose': 'closeKpiActivity'

  constructor: ->
    super

    if !@permissionCheck('ticket.agent')
      @clueAccess = false
      return

    # render page
    @render()

    # rerender view, e. g. on language change
    @controllerBind('ui:rerender', =>
      return if !@authenticateCheck()
      @render()
    )

    @mayBeClues()

  render: ->

    showTeamKpi = @permissionCheck('ticket.agent')

    localEl = $( App.view('dashboard')(
      head:        __('Dashboard')
      isAdmin:     @permissionCheck('admin')
      showTeamKpi: showTeamKpi
    ) )

    new App.DashboardStats(
      el: localEl.find('.stat-widgets')
    )

    if showTeamKpi
      new App.DashboardTeamKpi(
        el: localEl.find('.team-kpi-widgets')
      )

    new App.DashboardActivityStream(
      el:     localEl.find('.js-activityContent')
      limit:  25
      onLoad: @updateKpiActivityBadge
    )

    new App.DashboardFirstSteps(
      el: localEl.find('.first-steps-widgets')
    )

    @html localEl

    # KPI Tim adalah tab awal kalau tersedia (lihat dashboard.jst.eco)
    @el.addClass('team-kpi-host')
    @setKpiTab(showTeamKpi)
    @updateKpiActivityBadge(@kpiActivityItems) if @kpiActivityItems

    $(document).off('keydown.kpiActivity').on('keydown.kpiActivity', (e) =>
      return if e.key isnt 'Escape'
      return if !@shown || !@el.hasClass('is-activity-open')
      @closeKpiActivity()
    )

  # ---- KPI Tim: Activity Stream sebagai drawer --------------------------
  # Di tab KPI Tim sidebar Activity Stream disembunyikan supaya dashboard
  # dapat lebar penuh; tombol "Aktivitas" membukanya sebagai drawer.
  # Status buka/tutup + kapan terakhir dilihat disimpan di preferensi user
  # (kpi_activity_open, kpi_activity_seen_at) supaya ikut ke perangkat lain.
  # Tab My Stats / First Steps tetap memakai sidebar seperti biasa.
  # Lihat docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 14.

  kpiPreferences: =>
    @Session.get('preferences') || {}

  setKpiTab: (active) =>
    @el.toggleClass('is-kpi-tab', !!active)
    @applyKpiActivity()

  applyKpiActivity: =>
    open = !!@kpiPreferences().kpi_activity_open
    @el.toggleClass('is-activity-open', open)
    @$('.js-kpiActivityToggle').attr('aria-expanded', if open && @el.hasClass('is-kpi-tab') then 'true' else 'false')

  toggleKpiActivity: (e) =>
    e?.preventDefault()
    @saveKpiActivity(!@kpiPreferences().kpi_activity_open)

  closeKpiActivity: (e) =>
    e?.preventDefault()
    @saveKpiActivity(false)
    @$('.js-kpiActivityToggle').trigger('focus')

  # Buka atau tutup = aktivitas yang sedang tampil dianggap sudah dilihat.
  saveKpiActivity: (open) =>
    data =
      kpi_activity_open:    open
      kpi_activity_seen_at: @latestKpiActivity() || new Date().toISOString()
    _.extend(@kpiPreferences(), data)
    @applyKpiActivity()
    @updateKpiActivityBadge(@kpiActivityItems)
    App.Ajax.request(
      id:          'preferences_kpi_activity'
      type:        'PUT'
      url:         "#{@apiPath}/users/preferences"
      data:        JSON.stringify(data)
      processData: true
    )

  latestKpiActivity: =>
    items = @kpiActivityItems || []
    return null if !items.length
    # string ISO dibandingkan sebagai teks (_.max hanya untuk angka)
    _.reduce(items, ((latest, item) -> if !latest || item.created_at > latest then item.created_at else latest), null)

  # Badge = aktivitas orang lain setelah terakhir dilihat; kosong saat
  # drawer terbuka. Belum pernah dilihat = tanpa badge (bukan 25 sekaligus).
  updateKpiActivityBadge: (items) =>
    @kpiActivityItems = items
    badge = @$('.js-kpiActivityBadge')
    seenAt = @kpiPreferences().kpi_activity_seen_at
    me = App.Session.get('id')
    count = 0
    if seenAt && !@kpiPreferences().kpi_activity_open
      count = _.filter(items || [], (item) -> item.created_at > seenAt && item.created_by_id isnt me).length
    badge.toggleClass('hidden', count is 0)
    badge.text(if count > 99 then '99+' else "#{count}")
    badge.attr('aria-label', App.i18n.translateInline('%s aktivitas baru', count))

  release: =>
    $(document).off('keydown.kpiActivity')

  mayBeClues: =>
    return if @Config.get('after_auth')
    return if !@clueAccess
    return if !@shown
    return if @Config.get('switch_back_to_possible')
    preferences = @Session.get('preferences')
    @clueAccess = false

    # If the initial clue has been already completed by the user, show the rest of the clues.
    if preferences['intro']
      for clue in _.sortBy(App.Config.get('Clues'), 'prio')
        continue if preferences[clue.preference_key] # skip already completed clues
        continue if clue.config_key and not App.Config.get(clue.config_key) # skip clues about inactive features
        continue if clue.permission and not _.every(clue.permission, (permission) -> App.User.current()?.permission(permission)) # skip clues without required permissions

        new clue.controller(
          appEl: @appEl
          onComplete: =>
            App.Ajax.request(
              id:          'preferences'
              type:        'PUT'
              url:         "#{@apiPath}/users/preferences"
              data:        JSON.stringify("#{clue.preference_key}": true)
              processData: true
            )
        )

        return # show only one clue at a time

      return

    @clues()

  clues: (e) =>
    @clueAccess = false
    if e
      e.preventDefault()

    # Initial clue has its own controller, so it can be triggered via a route change later.
    @navigate '#clues'

  active: (state) =>
    return @shown if state is undefined
    @shown = state
    if state
      @mayBeClues()

  url: ->
    '#dashboard'

  show: (params) =>
    if @permissionCheck('ticket.agent')
      @title __('Dashboard')
      @navupdate '#dashboard'
    # in case of being only customer, redirect to default router
    else if @permissionCheck('ticket.customer')
      @navigate '#ticket/view', { hideCurrentLocationFromHistory: true }
    # in case of being only admin, redirect to admin interface (show no empty white content page)
    else if @permissionCheck('admin')
      @navigate '#manage', { hideCurrentLocationFromHistory: true }
    # fallback for user who is neither admin nor customer
    else
      @navigate '#welcome', { hideCurrentLocationFromHistory: true }

  changed: ->
    false

  toggle: (e) =>
    @$('.tabs .tab').removeClass('active')
    $(e.target).addClass('active')
    target = $(e.target).data('area')
    @$('.tab-content').addClass('hidden')
    @$(".tab-content.#{target}").removeClass('hidden')
    @setKpiTab(target is 'team-kpi-widgets')

class DashboardRouter extends App.ControllerPermanent
  @requiredPermission: ['*']

  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    App.TaskManager.execute(
      key:        'Dashboard'
      controller: 'Dashboard'
      params:     {}
      show:       true
      persistent: true
    )

App.Config.set('dashboard', DashboardRouter, 'Routes')
App.Config.set('Dashboard', { controller: 'Dashboard', permission: ['*'] }, 'permanentTask')
App.Config.set('Dashboard', { prio: 100, parent: '', name: __('Dashboard'), target: '#dashboard', key: 'Dashboard', permission: ['ticket.agent'], class: 'dashboard' }, 'NavBar')
