class App.Dashboard extends App.Controller
  clueAccess: true
  events:
    'click .tabs .tab': 'toggle'
    'click .js-intro': 'clues'
    'click .js-kpiActivityToggle': 'toggleKpiActivity'
    'click .js-kpiActivityClose': 'closeKpiActivity'
    'change .js-kpiActivityBots': 'toggleKpiBots'
    'click .js-kpiActivityMarkRead': 'markKpiActivityRead'

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
    # KPI Saya (Section 24) dibuat saat tabnya pertama kali dibuka (toggle)
    @kpiMine = null

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
    # batas "baru" di drawer = terakhir dilihat sebelum drawer dibuka
    @kpiSeenBefore = @kpiPreferences().kpi_activity_seen_at
    @setKpiTab(showTeamKpi)
    @updateKpiActivityBadge(@kpiActivityItems) if @kpiActivityItems

    # waktu relatif ("5 mnt lalu") diperbarui tiap menit selama drawer terbuka
    clearInterval(@kpiActivityTimer) if @kpiActivityTimer
    @kpiActivityTimer = setInterval(=>
      @renderKpiActivity() if @el.hasClass('is-kpi-tab') && @el.hasClass('is-activity-open')
    , 60000)

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
    @renderKpiActivity()

  toggleKpiActivity: (e) =>
    e?.preventDefault()
    open = !@kpiPreferences().kpi_activity_open
    @kpiSeenBefore = @kpiPreferences().kpi_activity_seen_at if open
    @saveKpiActivity(open)

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
    @renderKpiActivity()
    badge = @$('.js-kpiActivityBadge')
    seenAt = @kpiPreferences().kpi_activity_seen_at
    me = App.Session.get('id')
    count = 0
    if seenAt && !@kpiPreferences().kpi_activity_open
      count = _.filter(items || [], (item) -> item.created_at > seenAt && item.created_by_id isnt me).length
    badge.toggleClass('hidden', count is 0)
    badge.text(if count > 99 then '99+' else "#{count}")
    badge.attr('aria-label', App.i18n.translateInline('%s aktivitas baru', count))

  # ---- isi drawer (hanya tab KPI Tim; tab lain memakai daftar bawaan) ----
  # Mockup TeamKpi-Activity-Open. Satu aksi agent biasanya = 2 item (pesan +
  # tiket), jadi item digabung per (aktor, tiket) selama berurutan. Aktor
  # tanpa nama / user sistem (id 1, tampil "- updated ticket") = Otomatisasi,
  # disembunyikan kecuali dicentang (preferensi kpi_activity_show_bots).

  KPI_VERBS:
    Ticket:
      create:                  'membuat tiket'
      update:                  'memperbarui tiket'
      escalation:              'menandai tiket lewat SLA'
      escalation_warning:      'menandai tiket hampir lewat SLA'
      reminder_reached:        'pengingat tiket tercapai'
      'update.merged_into':    'menggabungkan tiket'
      'update.received_merge': 'menerima gabungan tiket'
    TicketArticle:
      create:            'menambah pesan di tiket'
      update:            'memperbarui pesan di tiket'
      'update.reaction': 'memberi reaksi di tiket'

  # urutan kata kerja yang mewakili grup (aksi paling berarti dulu)
  KPI_VERB_RANK: ['Ticket:create', 'Ticket:escalation', 'Ticket:escalation_warning', 'TicketArticle:create', 'Ticket:update']

  # Item disiapkan sendiri (seperti prepareForObjectListItem): collection
  # controller hanya menyiapkan item yang dirender ulang, dan record dibuat
  # baru setiap load -- tanpa ini created_by kosong & semua terbaca otomatisasi.
  kpiPrepare: (raw) ->
    item = _.clone(raw)
    item.object = (item.object || '').replace(/::/g, '')
    model = App[item.object]
    if model?.exists?(item.o_id)
      object = model.findNative(item.o_id)
      item.objectNative = object
      item.link         = object.uiUrl?() || ''
      item.title        = object.displayName?() || '-'
      item.object_name  = object.objectDisplayName?()
    item.created_by = if App.User.exists(item.created_by_id) then App.User.findNative(item.created_by_id) else null
    item

  # user sistem (id 1) atau user tanpa nama ("-"); user yang belum termuat
  # tidak dianggap otomatisasi
  kpiIsBot: (item) ->
    return true if item.created_by_id is 1
    return false if !item.created_by
    name = item.created_by.displayName?() || ''
    !name.replace(/^-$/, '').trim()

  kpiTicketId: (item) ->
    return item.o_id if item.object is 'Ticket'
    return item.objectNative?.ticket_id if item.object is 'TicketArticle'
    null

  kpiVerb: (item) =>
    @KPI_VERBS[item.object]?[item.type] || (if item.type is 'create' then "membuat #{(item.object_name || item.object).toLowerCase()}" else "memperbarui #{(item.object_name || item.object).toLowerCase()}")

  kpiPad: (n) -> if n < 10 then "0#{n}" else "#{n}"

  kpiRelative: (date, now) ->
    minutes = Math.floor((now - date) / 60000)
    return 'baru saja' if minutes < 1
    return "#{minutes} mnt lalu" if minutes < 60
    hours = Math.floor(minutes / 60)
    return "#{hours} jam lalu" if hours < 24
    return 'kemarin' if hours < 48
    "#{Math.floor(hours / 24)} hari lalu"

  kpiClock: (date, now) =>
    time = "#{@kpiPad(date.getHours())}:#{@kpiPad(date.getMinutes())}"
    return time if date.toDateString() is now.toDateString()
    months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des']
    "#{date.getDate()} #{months[date.getMonth()]} #{time}"

  kpiActivityView: (items) =>
    prefs    = @kpiPreferences()
    showBots = !!prefs.kpi_activity_show_bots
    me       = App.Session.get('id')
    seen     = @kpiSeenBefore
    now      = new Date()
    groups   = []
    botCount = 0
    sorted = _.sortBy(_.map(items || [], @kpiPrepare), (item) -> item.created_at).reverse()
    for item in sorted
      bot = @kpiIsBot(item)
      botCount += 1 if bot
      continue if bot && !showBots
      ticketId = @kpiTicketId(item)
      key = "#{item.created_by_id}|#{if ticketId then "t#{ticketId}" else "#{item.object}#{item.o_id}"}"
      last = _.last(groups)
      if last && last.key is key
        last.items.push(item)
      else
        groups.push({ key: key, ticketId: ticketId, bot: bot, items: [item] })

    rows = for g in groups
      first  = g.items[0]
      oldest = _.last(g.items)
      ticket = if g.ticketId && App.Ticket.exists(g.ticketId) then App.Ticket.findNative(g.ticketId) else null
      kinds  = _.map(g.items, (i) -> "#{i.object}:#{i.type}")
      rank   = _.find(@KPI_VERB_RANK, (k) -> _.contains(kinds, k))
      main   = if rank then _.find(g.items, (i) -> "#{i.object}:#{i.type}" is rank) else first
      newest = new Date(first.created_at)
      older  = new Date(oldest.created_at)
      clock  = @kpiClock(newest, now)
      clock  = "#{@kpiClock(older, now)}–#{clock.split(' ').pop()}" if g.items.length > 1 && Math.floor(newest / 60000) isnt Math.floor(older / 60000) && newest.toDateString() is older.toDateString()
      name   = first.created_by?.displayName?() || 'Pengguna'
      {
        bot:       g.bot
        actor:     name
        initials:  _.map(name.split(/\s+/).slice(0, 2), (w) -> w.charAt(0).toUpperCase()).join('')
        verb:      @kpiVerb(main)
        # pesan + tiket dari satu aksi "buat tiket" tidak dihitung sebagai 2×
        count:     if g.items.length > 1 && !_.contains(kinds, 'Ticket:create') then g.items.length else null
        title:     ticket?.title || first.title
        link:      ticket?.uiUrl() || first.link
        relative:  @kpiRelative(newest, now)
        clock:     clock
        timeTitle: newest.toLocaleString()
        isNew:     !!seen && _.some(g.items, (i) -> i.created_at > seen && i.created_by_id isnt me)
      }

    {
      illus:    App.view('dashboard/team_kpi_illus')(key: 'activity')
      groups:   rows
      newCount: _.filter(rows, (r) -> r.isNew).length
      showBots: showBots
      botCount: botCount
      # daftar kosong karena semua item otomatisasi yang sedang disembunyikan
      allHidden: !rows.length && botCount > 0 && !showBots
    }

  renderKpiActivity: =>
    el = @$('.js-kpiActivityView')
    return if !el.length
    el.html(App.view('dashboard/kpi_activity')(@kpiActivityView(@kpiActivityItems)))

  toggleKpiBots: (e) =>
    show = $(e.currentTarget).prop('checked')
    _.extend(@kpiPreferences(), { kpi_activity_show_bots: show })
    @renderKpiActivity()
    App.Ajax.request(
      id:          'preferences_kpi_activity_bots'
      type:        'PUT'
      url:         "#{@apiPath}/users/preferences"
      data:        JSON.stringify(kpi_activity_show_bots: show)
      processData: true
    )

  # Semua yang tampil dianggap sudah dibaca (highlight hilang, badge nol).
  markKpiActivityRead: (e) =>
    e?.preventDefault()
    @kpiSeenBefore = @latestKpiActivity()
    @saveKpiActivity(!!@kpiPreferences().kpi_activity_open)

  release: =>
    clearInterval(@kpiActivityTimer) if @kpiActivityTimer
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
    if target is 'team-kpi-mine-widgets' && !@kpiMine
      @kpiMine = new App.DashboardKpiMine(el: @$('.team-kpi-mine-widgets'))
    # KPI Saya memakai tata letak & drawer Aktivitas yang sama dengan KPI Tim
    @setKpiTab(target in ['team-kpi-widgets', 'team-kpi-mine-widgets'])

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
