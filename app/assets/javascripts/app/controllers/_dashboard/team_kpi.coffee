# "KPI Tim" Dashboard tab -- redesign BI (mockup B di kanvas desain "SISKA
# Widget - Kit Tailwind Compliance", artboard TeamKpi-KitB), gaya kit Able
# Pro seperti panel agent (siska_agent_chat.scss). Data dari endpoint Fase
# 2/3 (docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 10-12):
#   /team_kpi (kartu, antrian, SLA, backlog, pembanding, ambang),
#   /team_kpi/trend, /team_kpi/heatmap, /team_kpi/agents (hanya team_kpi.agents/admin),
#   /team_kpi/export (unduhan .xlsx dengan filter yang sama).
#
# Semua hitungan tampilan (skala state, delta, data grafik, ringkasan heatmap)
# dilakukan di sini; team_kpi.jst.eco hanya menampilkan.
#
# Tata letak (artboard TeamKpi-Tabs, Section 15): filter -> antrian real-time
# -> 6 kartu -> kartu rincian ber-nav-tabs (Tren / Pola beban / SLA & Backlog
# / Per agent). Tab terakhir diingat per user (preferensi kpi_detail_tab);
# data tren/heatmap/agent hanya diambil untuk tab yang aktif. Grafik tren &
# heatmap = ApexCharts 4.7.0 dari kit (public/assets/siska/apexcharts/),
# dimuat lazy sekali saat dibutuhkan.
#
# Quick win (Section 18, artboard TeamKpi-QuickWin): filter Pembanding
# (form-select) + Prioritas/Kanal/Kategori (Choices.js 11.1.0 dari kit,
# public/assets/siska/choices/, juga dimuat lazy), cakupan rating CSAT, dan
# drill-down kartu -> App.DashboardTeamKpiDrill (modal daftar tiket).
class App.DashboardTeamKpi extends App.Controller
  events:
    'change .js-kpi-period': 'onPeriod'
    'change .js-kpi-group':  'onGroup'
    'click .js-kpi-tab':     'onTab'
    'click .js-kpi-metric':  'onMetric'
    'click .js-kpi-export':  'onExport'
    'click .js-kpi-retry':   'onRetry'
    'change .js-kpi-compare': 'onCompare'
    'change .js-kpi-multi':   'onMulti'
    'click .js-kpi-reset':    'onReset'
    'click .js-kpi-drill':    'onDrill'
    'click .js-kpi-tab-link': 'onTab'
    'change .js-kpi-topic-sort': 'onTopicSort'
    'click .js-kpi-topic-small': 'onTopicSmall'

  # Sub-tab rincian; part = bagian API yang hanya diambil saat tab aktif.
  TABS: [
    { key: 'trend',  label: 'Tren',          part: 'trend' }
    { key: 'load',   label: 'Pola beban',    part: 'heatmap' }
    { key: 'sla',    label: 'SLA & Backlog', part: null }
    { key: 'topic',  label: 'Per help topic', part: null }
    { key: 'agents', label: 'Per agent',     part: 'agents' }
  ]

  APEX_URL: '/assets/siska/apexcharts/apexcharts-4.7.0.min.js'
  CHOICES_URL: '/assets/siska/choices/choices-11.1.0.min.js'

  # Pembanding (param compare API); 'auto' = aturan bawaan (Section 10.3).
  COMPARES: [
    { value: 'auto',     label: 'Otomatis' }
    { value: 'previous', label: 'Periode sebelumnya' }
    { value: 'yoy',      label: 'Tahun lalu, periode sama' }
    { value: 'none',     label: 'Tanpa pembanding' }
  ]

  # Multi-select Choices.js; source = kunci di /team_kpi/filter_options.
  MULTI_FILTERS: [
    { key: 'priority_ids', label: 'Prioritas', placeholder: 'Semua prioritas', source: 'priorities' }
    { key: 'channels',     label: 'Kanal',     placeholder: 'Semua kanal',     source: 'channels' }
    { key: 'categories',   label: 'Kategori',  placeholder: 'Semua kategori',  source: 'categories' }
  ]

  # Di bawah ini cakupan rating CSAT (rating / tiket closed) dianggap belum
  # representatif; sampel kecil (SMALL_SAMPLE) juga ditandai.
  CSAT_COVERAGE_MIN: 5

  PERIODS: [
    { days: 7,   label: '7 hari' }
    { days: 30,  label: '30 hari' }
    { days: 90,  label: '90 hari' }
    { days: 180, label: '180 hari' }
    { days: 365, label: '1 tahun' }
    { days: 730, label: '2 tahun' }
  ]

  METRICS: [
    { key: 'frt',        label: 'FRT median',   kind: 'duration', lowerBetter: true }
    { key: 'csat',       label: 'CSAT',         kind: 'score',    lowerBetter: false }
    { key: 'volume',     label: 'Tiket masuk',  kind: 'count',    lowerBetter: null }
    { key: 'resolution', label: 'Penyelesaian', kind: 'duration', lowerBetter: true }
    { key: 'escalated',  label: 'Rasio Escalated', kind: 'rate', lowerBetter: true }
  ]

  STATES: ['supergood', 'good', 'ok', 'bad', 'superbad']
  STATE_LABELS:
    supergood: 'Sangat baik'
    good:      'Baik'
    ok:        'Cukup'
    bad:       'Buruk'
    superbad:  'Sangat buruk'

  BACKLOG_LABELS:
    lt_1d:   '< 1 hari'
    d1_3:    '1–3 hari'
    d3_7:    '3–7 hari'
    d7_30:   '7–30 hari'
    gte_30d: '≥ 30 hari'

  WEEKDAYS: ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu']
  MONTHS: ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des']

  # Di bawah ini sampel dianggap kecil (angka belum bisa diandalkan).
  SMALL_SAMPLE: 30

  constructor: ->
    super
    # Setting team_kpi_default_window_days (frontend: true) = default yang
    # sama dengan backend; 7 hanya cadangan kalau config tidak ada.
    @days = parseInt(App.Config.get('team_kpi_default_window_days'), 10) || 7
    @days = 7 if !_.find(@PERIODS, (p) => p.days is @days)
    @groupId = ''
    @compare = 'auto'
    @filters = { priority_ids: [], channels: [], categories: [] }
    @choices = []
    @metric  = 'frt'
    @topicSort  = 'count'
    @topicSmall = false
    # sama dengan TeamKpiController#agents_access? (dokumen Section 19)
    @canSeeAgents = @permissionCheck('team_kpi.agents') || @permissionCheck('admin')
    @tab = @preferences()[@TAB_PREF]
    @tab = 'trend' if !_.find(@availableTabs(), (t) => t.key is @tab)
    @data    = {}
    @dataKey = {}   # part -> partKey saat data diambil (data lama tidak dipakai)
    @charts  = {}
    @load()
    @startAutoRefresh()

  # preferensi tab rincian terakhir (KPI Saya punya kunci sendiri)
  TAB_PREF: 'kpi_detail_tab'
  # nama di pesan gagal
  KPI_NAME: 'KPI Tim'

  preferences: ->
    App.Session.get('preferences') || {}

  availableTabs: =>
    _.filter(@TABS, (t) => t.key isnt 'agents' || @canSeeAgents)

  tabPart: =>
    _.find(@TABS, (t) => t.key is @tab)?.part

  # Kunci filter per bagian: data yang diambil dengan filter lain dianggap
  # belum ada (tampil "Memuat…" lalu diambil ulang), bukan ditampilkan.
  partKey: (part) =>
    key = $.param(@params())
    key += "&metric=#{@metric}" if part is 'trend'
    key

  hasPart: (part) =>
    !!@data[part] && @dataKey[part] is @partKey(part)

  onTab: (e) =>
    e.preventDefault()
    tab = $(e.currentTarget).data('tab')
    return if tab is @tab || !_.find(@availableTabs(), (t) -> t.key is tab)
    @tab = tab
    @saveTab()
    part = @tabPart()
    if part && !@hasPart(part)
      @loadParts([part])
    else
      @render()
      # dari tautan di dalam pane (mis. "Lihat semua help topic"): fokus ke tab tujuan
      @$('.js-kpi-tab.is-active').trigger('focus') if $(e.currentTarget).hasClass('js-kpi-tab-link')

  # Sama dengan drawer Aktivitas (dashboard.coffee): preferensi user di
  # server supaya ikut ke perangkat/browser lain.
  saveTab: =>
    data = {}
    data[@TAB_PREF] = @tab
    prefs = App.Session.get('preferences')
    _.extend(prefs, data) if prefs
    App.Ajax.request(
      id:          "preferences_#{@TAB_PREF}"
      type:        'PUT'
      url:         "#{@apiPath}/users/preferences"
      data:        JSON.stringify(data)
      processData: true
    )

  # Sub-tab Per help topic (Section 23): urutan & topik kecil hanya di tampilan.
  onTopicSort: (e) =>
    sort = $(e.currentTarget).val()
    return if !_.find(@TOPIC_SORTS, (o) -> o.value is sort)
    @topicSort = sort
    @render()

  onTopicSmall: (e) =>
    e.preventDefault()
    @topicSmall = !@topicSmall
    @render()

  onPeriod: (e) =>
    days = parseInt($(e.currentTarget).val(), 10)
    return if !days
    @days = days
    @load()

  onGroup: (e) =>
    @groupId = $(e.currentTarget).val()
    @load()

  onCompare: (e) =>
    @compare = $(e.currentTarget).val() || 'auto'
    @load()

  # Choices.js meneruskan perubahan ke <select multiple> aslinya (event change).
  onMulti: (e) =>
    key = $(e.currentTarget).data('filter')
    return if !@filters[key]
    @filters[key] = _.compact(_.flatten([$(e.currentTarget).val() || []]))
    @load()

  onReset: (e) =>
    e.preventDefault()
    @groupId = ''
    @compare = 'auto'
    @filters = { priority_ids: [], channels: [], categories: [] }
    @load()

  onDrill: (e) =>
    e.preventDefault()
    new App.DashboardTeamKpiDrill(kpi: @, metric: $(e.currentTarget).data('metric'))

  hasFilters: =>
    !!@groupId || @compare isnt 'auto' || _.some(@MULTI_FILTERS, (f) => @filters[f.key].length > 0)

  # Keterangan filter aktif untuk judul modal drill-down.
  filterSummary: =>
    opts  = @data.options || {}
    parts = []
    if @groupId
      group = _.find(@groupOptions(), (g) => String(g.id) is String(@groupId))
      parts.push("Grup #{group?.name || @groupId}")
    for f in @MULTI_FILTERS when @filters[f.key].length
      labels = for v in @filters[f.key]
        o = _.find(opts[f.source] || [], (x) => String(x.id ? x.value ? x.name) is String(v))
        o?.label || o?.name || v
      parts.push("#{f.label} #{labels.join(', ')}")
    parts

  onMetric: (e) =>
    e.preventDefault()
    @metric = $(e.currentTarget).data('metric')
    if @hasPart('trend') then @render() else @loadParts(['trend'])

  onRetry: (e) =>
    e.preventDefault()
    @load()

  # Sesi login agent (cookie) ikut terkirim, jadi cukup navigasi ke URL
  # ekspor dengan filter yang sama; browser mengunduh .xlsx-nya.
  onExport: (e) =>
    e.preventDefault()
    window.location.href = @exportUrl()

  exportUrl: =>
    "#{@apiPath}/team_kpi/export?#{$.param(@params())}"

  params: =>
    params = { days: @days }
    params.group_ids = @groupId if @groupId
    params.compare   = @compare if @compare isnt 'auto'
    for f in @MULTI_FILTERS when @filters[f.key].length
      params[f.key] = @filters[f.key].join(',')
    params

  # Ringkasan (kartu, antrian, SLA, backlog) selalu; tren/heatmap/agent hanya
  # untuk tab yang sedang aktif -- tab lain diambil saat dibuka.
  load: (silent = false) =>
    parts = ['summary', 'options']
    part  = @tabPart()
    parts.push(part) if part
    @loadParts(parts, silent)

  # Semua bagian diambil paralel, render sekali setelah semuanya selesai
  # (berhasil atau gagal). Bagian yang gagal tetap menampilkan data
  # sebelumnya + banner "angka terakhir pukul ..." -- kondisi "Gagal
  # memuat" di artboard kondisi data mockup.
  loadParts: (parts, silent = false) =>
    @loading = true
    @render() if !silent
    pending = parts.length
    failed  = []
    done = =>
      pending -= 1
      return if pending > 0
      @loading = false
      @failed  = failed
      @render()

    for part in parts
      do (part) =>
        req = @partRequest(part)
        key = @partKey(part)
        @ajax(
          id:          "team_kpi_#{part}"
          type:        'GET'
          url:         req.url
          data:        req.data
          processData: true
          success: (response) =>
            @data[part]    = response
            @dataKey[part] = key
            @fetchedAt     = new Date() if part is 'summary'
            done()
          error: =>
            # daftar filter tanpa jumlah tetap bisa dipakai -> bukan "gagal"
            failed.push(part) if !_.contains(@OPTIONAL_PARTS, part)
            done()
        )

  # bagian yang boleh gagal tanpa banner "gagal dimuat"
  OPTIONAL_PARTS: ['options']

  # URL + parameter tiap bagian (turunan menambah bagian sendiri).
  partRequest: (part) =>
    data = @params()
    data.metric = @metric if part is 'trend'
    data.limit  = 50 if part is 'agents'
    urls =
      summary: "#{@apiPath}/team_kpi"
      trend:   "#{@apiPath}/team_kpi/trend"
      heatmap: "#{@apiPath}/team_kpi/heatmap"
      agents:  "#{@apiPath}/team_kpi/agents"
      options: "#{@apiPath}/team_kpi/filter_options"
    { url: urls[part], data: data }

  # Configurable via Setting team_kpi_auto_refresh_seconds (default 300s,
  # 0 = mati). Timer jalan terus, tapi request hanya dikirim kalau tab
  # browser terlihat DAN sub-tab KPI Tim sedang aktif (Dashboard#toggle
  # memasang .hidden di @el saat pindah ke My Stats/First Steps).
  startAutoRefresh: =>
    seconds = parseInt(App.Config.get('team_kpi_auto_refresh_seconds'), 10)
    return if !seconds || seconds <= 0

    @autoRefreshTimer = setInterval(@maybeAutoRefresh, seconds * 1000)

  maybeAutoRefresh: =>
    return if document.hidden
    return if @el.hasClass('hidden')

    @load(true)

  release: =>
    clearInterval(@autoRefreshTimer) if @autoRefreshTimer
    @destroyCharts()
    @destroyChoices()

  # ------------------------------------------------------------- format

  fmtNumber: (value, digits = 1) ->
    return '—' if !value? || _.isNaN(value)
    factor  = Math.pow(10, digits)
    rounded = Math.round(value * factor) / factor
    rounded.toLocaleString('id-ID', { maximumFractionDigits: digits })

  # Menit -> satuan yang terbaca (mis. mean 890 mnt = 14,8 jam).
  fmtDuration: (minutes) =>
    return { value: '—', unit: '' } if !minutes?
    return { value: @fmtNumber(minutes, 1), unit: 'mnt' } if minutes < 60
    return { value: @fmtNumber(minutes / 60, 1), unit: 'jam' } if minutes < 1440
    { value: @fmtNumber(minutes / 1440, 1), unit: 'hari' }

  fmtDurationText: (minutes) =>
    d = @fmtDuration(minutes)
    return d.value if !d.unit
    "#{d.value} #{d.unit}"

  # Menit KERJA (kalender SLA, 1 hari kerja = 9 jam = 540 menit, Sen–Jum
  # 08.00–17.00): mis. solution_time SLA 1620 = "3 hari kerja", bukan 1,1 hari.
  WORK_DAY_MINUTES: 540

  fmtWorkDuration: (minutes) =>
    return '—' if !minutes?
    if minutes >= @WORK_DAY_MINUTES && minutes % @WORK_DAY_MINUTES is 0
      "#{minutes / @WORK_DAY_MINUTES} hari kerja"
    else if minutes >= 60
      "#{@fmtNumber(minutes / 60, 1)} jam kerja"
    else
      "#{@fmtNumber(minutes, 0)} mnt kerja"

  # Durasi FRT sesuai Setting "Dasar waktu FRT" (jam kerja: 1 hari = 9 jam).
  fmtFrt: (minutes, basis = @data.summary?.frt_time_basis) =>
    if basis is 'business' then @fmtWorkDuration(minutes) else @fmtDurationText(minutes)

  fmtFrtParts: (minutes, basis) =>
    return @fmtDuration(minutes) if basis isnt 'business' || !minutes?
    text = @fmtWorkDuration(minutes)
    i = text.indexOf(' ')
    { value: text.substr(0, i), unit: text.substr(i + 1) }

  pad2: (n) ->
    if n < 10 then "0#{n}" else "#{n}"

  isoDate: (date) =>
    "#{date.getFullYear()}-#{@pad2(date.getMonth() + 1)}-#{@pad2(date.getDate())}"

  fmtDate: (iso, withYear = false) =>
    date = new Date("#{iso.substr(0, 10)}T00:00:00")
    text = "#{date.getDate()} #{@MONTHS[date.getMonth()]}"
    text += " #{date.getFullYear()}" if withYear
    text

  fmtRange: (period) =>
    return '' if !period
    from = new Date(period.from)
    to   = new Date(new Date(period.to).getTime() - 1000)
    sameYear = from.getFullYear() is to.getFullYear()
    "#{@fmtDate(@isoDate(from), !sameYear)} – #{@fmtDate(@isoDate(to), true)}"

  fmtTime: (date) =>
    return '' if !date
    "#{@pad2(date.getHours())}:#{@pad2(date.getMinutes())}"

  fmtDateTime: (iso) =>
    return '' if !iso
    date = new Date(iso)
    "#{date.getDate()} #{@MONTHS[date.getMonth()]} #{@fmtTime(date)}"

  # Tanggal lengkap (zona waktu browser) untuk daftar drill-down 1-2 tahun.
  fmtDateTimeYear: (iso) =>
    return '—' if !iso
    date = new Date(iso)
    "#{date.getDate()} #{@MONTHS[date.getMonth()]} #{date.getFullYear()} #{@fmtTime(date)}"

  # Catatan kenapa kartu/antrian real-time tidak punya delta "vs kemarin"
  # (lihat realtime_comparison di team_kpi.rb, snapshot per jam Section 13).
  realtimeNote: (rc) =>
    return 'Real-time' if !rc
    switch rc.reason
      when 'filters'     then 'Real-time · delta tidak tersedia dengan filter ini'
      when 'agent'       then 'Real-time · snapshot hanya per grup, tanpa delta per agent'
      when 'no_snapshot' then "Real-time · snapshot kemarin belum ada (dikumpulkan sejak #{@fmtDateTime(rc.history_since)})"
      else                    'Real-time · snapshot belum dikumpulkan'

  periodLabel: =>
    period = _.find(@PERIODS, (p) => p.days is @days)
    "#{period.label} terakhir"

  # ------------------------------------------------------------- kartu

  # Skala 5 tingkat + label ambang dari summary.thresholds (Setting server).
  scale: (state, kind, t) =>
    return null if !t
    tips = switch kind
      when 'frt'  then ["≤ #{@fmtDurationText(t.supergood_max)}", "≤ #{@fmtDurationText(t.good_max)}", "≤ #{@fmtDurationText(t.ok_max)}", "≤ #{@fmtDurationText(t.bad_max)}", "> #{@fmtDurationText(t.bad_max)}"]
      when 'csat' then ["≥ #{t.supergood_min}", "≥ #{t.good_min}", "≥ #{t.ok_min}", "≥ #{t.bad_min}", "< #{t.bad_min}"]
      # % sesuai target, dari ambang Rasio Escalated atas % terlambat (Section 22.4)
      when 'met'  then ["> #{t.supergood_above}%", "> #{t.good_above}%", "> #{t.ok_above}%", "> #{t.bad_above}%", "≤ #{t.bad_above}%"]
      else             ["< #{t.good_min}%", "≥ #{t.good_min}%", "≥ #{t.ok_min}%", "≥ #{t.bad_min}%", "≥ #{t.superbad_min}%"]
    segs = for s, i in @STATES
      { state: s, active: s is state, tip: "#{@STATE_LABELS[s]}: #{tips[i]}" }
    { segs: segs, first: "#{@STATE_LABELS.supergood} #{tips[0]}" }

  # Baris konteks kartu FRT (Section 22.5): % sesuai target, target yang
  # berlaku, dan perubahannya dalam poin. Jam kerja diberi akhiran "kerja".
  frtContext: (s, cmp) =>
    return null if !s.frt_target_met_percent?
    work = if s.frt_time_basis is 'business' then ' kerja' else ''
    target = if s.frt_target_minutes?
      "target #{if work then @fmtWorkDuration(s.frt_target_minutes) else @fmtDurationText(s.frt_target_minutes)}"
    else
      { help_topic: 'target per help topic', channel: 'target per kanal', group: 'target per grup' }[s.frt_target_basis] || 'target per help topic'
    text = "#{@fmtNumber(s.frt_target_met_percent, 1)}% tiket sesuai target · #{target}"
    if cmp?.frt_target_met_percent?
      d = s.frt_target_met_percent - cmp.frt_target_met_percent
      text += if Math.abs(d) < 0.05 then ' · = sama' else " · #{if d > 0 then '▲' else '▼'} #{@fmtNumber(Math.abs(d), 1)} poin"
    text

  # "jam kerja Sen–Jum 08.00–17.00 (kalender Indonesia/Jakarta)" dari heatmap.business_hours.
  businessHoursText: (bh) =>
    return 'jam kerja Sen–Jum 08.00–17.00' if !bh
    names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
    fmt = (h) => "#{@pad2(Math.floor(h))}.#{@pad2(Math.round((h % 1) * 60))}"
    groups = []
    for dow in [1..7]
      frames = (bh.days[dow] || [])
      continue if !frames.length
      key = _.map(frames, (f) -> "#{fmt(f[0])}–#{fmt(f[1])}").join(', ')
      last = _.last(groups)
      if last && last.key is key && last.to is dow - 1
        last.to = dow
      else
        groups.push({ key: key, from: dow, to: dow })
    days = _.map(groups, (g) -> "#{names[g.from - 1]}#{if g.to > g.from then '–' + names[g.to - 1] else ''} #{g.key}").join('; ')
    "jam kerja #{days || '—'} (kalender #{bh.calendar})"

  # Baris konteks kartu Waktu penyelesaian: % closed dalam batas SLA (+ poin).
  slaContext: (s, cmp) =>
    return null if !s.sla_within_percent?
    text = "#{@fmtNumber(s.sla_within_percent, 1)}% selesai dalam batas SLA · target SLA per help topic"
    if cmp?.sla_within_percent?
      d = s.sla_within_percent - cmp.sla_within_percent
      text += if Math.abs(d) < 0.05 then ' · = sama' else " · #{if d > 0 then '▲' else '▼'} #{@fmtNumber(Math.abs(d), 1)} poin"
    text

  # Selisih terhadap pembanding, diwarnai membaik/memburuk sesuai arah metrik.
  delta: (current, previous, kind, lowerBetter) =>
    return null if !current? || !previous?
    diff = current - previous
    return { text: '= sama', cls: 'is-flat' } if Math.abs(diff) < 0.005
    arrow = if diff > 0 then '▲' else '▼'
    text = switch kind
      when 'duration' then "#{@fmtDurationText(Math.abs(diff))} #{if diff < 0 then 'lebih cepat' else 'lebih lambat'}"
      when 'rate'     then "#{@fmtNumber(Math.abs(diff), 1)} poin"
      when 'count'    then @fmtNumber(Math.abs(diff), 0)
      else                 @fmtNumber(Math.abs(diff), 2)
    return { text: "#{arrow} #{text}", cls: 'is-flat' } if !lowerBetter?
    better = if lowerBetter then diff < 0 else diff > 0
    { text: "#{arrow} #{text}", cls: if better then 'is-better' else 'is-worse' }

  # Nilai persen gaya kit widget/w_statistics.html: angka = jumlah tiket,
  # badge = persen (warna status, panah = arah perubahan vs pembanding),
  # kalimat "Naik/Turun X poin vs ..." (team_kpi_pct.jst.eco).
  PCT_TONE:
    supergood: 'success'
    good:      'success'
    ok:        'warning'
    bad:       'danger'
    superbad:  'danger'

  pctView: (o) =>
    empty = !o.pct?
    change = null
    if !empty && o.prev?
      diff = o.pct - o.prev
      if Math.abs(diff) < 0.05
        change = { same: true, vs: o.vs }
      else
        better = if o.lowerBetter then diff < 0 else diff > 0
        change =
          word:   if diff > 0 then 'Naik' else 'Turun'
          amount: "#{@fmtNumber(Math.abs(diff), 1)} poin"
          cls:    if better then 'is-better' else 'is-worse'
          vs:     o.vs
          dir:    if diff > 0 then 'up' else 'down'
    view =
      empty:     empty
      value:     if empty then '—' else @fmtNumber(o.count, 0)
      unit:      'tiket'
      badge:     { text: (if empty then '—' else "#{@fmtNumber(o.pct, 1)}%"), tone: (if empty then 'secondary' else o.tone || 'secondary'), dir: change?.dir }
      badgeTip:  o.badgeTip
      baseLabel: o.baseLabel
      baseCount: @fmtNumber(o.baseCount, 0)
      baseUnit:  o.baseUnit
      change:    change
      note:      o.note
      emptyNote: o.emptyNote
    App.view('dashboard/team_kpi_pct')(view)

  # Cakupan rating = rating masuk / tiket closed di periode. "Tingkat respons
  # survei" belum bisa dihitung: rating dari widget tidak mengisi
  # csat_email_sent_at. Rendah (< CSAT_COVERAGE_MIN %) atau n kecil -> peringatan.
  csatCoverage: (s) =>
    closed = s.reopen_closed_count
    return null if !s.csat_count || !closed
    pct = s.csat_count / closed * 100
    {
      pct:    @fmtNumber(pct, if pct < 1 then 2 else 1)
      rated:  @fmtNumber(s.csat_count, 0)
      closed: @fmtNumber(closed, 0)
      low:    pct < @CSAT_COVERAGE_MIN || s.csat_count < @SMALL_SAMPLE
    }

  # Catatan real-time tanpa awalan "Real-time · " (sudah ada di kepala kartu).
  realtimeReason: (rc) =>
    note = @realtimeNote(rc).replace(/^Real-time( · )?/, '')
    return null if !note
    note.charAt(0).toUpperCase() + note.substr(1)

  cards: (s) =>
    t   = s.thresholds || {}
    cmp = s.comparison
    rc  = s.realtime_comparison
    cmpLabel = if cmp?.mode is 'yoy' then 'tahun lalu, periode sama' else 'periode sebelumnya'
    basis = @periodLabel()
    frt = @fmtFrtParts(s.frt_median_minutes, s.frt_time_basis)
    res = @fmtDuration(s.resolution_median_minutes)
    outlier = s.frt_median_minutes? && s.frt_mean_minutes? && s.frt_mean_minutes > s.frt_median_minutes * 3
    active  = (s.ticket_new || 0) + (s.ticket_open || 0)

    card = (o) =>
      # sampel kecil (< SMALL_SAMPLE): status tetap tampil + peringatan (Section 22.5)
      o.small      = !o.live && o.n? && o.n > 0 && o.n < @SMALL_SAMPLE
      o.stateKey   = o.state || 'none'
      o.empty      = o.value is '—'
      # anatomi seragam (docs Section 17): tiap kartu punya pill status;
      # metrik tanpa ambang (Setting) ditandai jelas, bukan dikosongkan
      o.stateLabel = if o.state then @STATE_LABELS[o.state] else (if o.neutral && !o.empty then 'Belum ada target' else 'Tidak ada data')
      o.noTarget   = o.neutral && !o.empty
      o.scale      = if o.state && o.scaleKind then @scale(o.state, o.scaleKind, t[o.scaleKey]) else null
      # tanpa data: placeholder "—" tetap membawa satuan metriknya (— mnt, — / 5)
      o.unit       = o.emptyUnit if o.empty && o.emptyUnit
      # baris bawah yang nilainya ikut kosong (mis. mean) tidak menambah informasi
      o.hideFoot   = o.footValue is '—'
      o.illusHtml  = App.view('dashboard/team_kpi_illus')(key: o.illus)
      o.drill      = null if o.drill && !o.drillCount
      if o.live && rc?.available
        d = @delta(o.current, o.previous, o.deltaKind, true)
        if d
          o.deltaText = d.text
          o.deltaCls  = d.cls
          o.deltaVs   = 'vs kemarin, jam sama'
        else
          o.deltaNote = 'vs kemarin: belum ada data'
      else if o.live
        o.deltaNote = @realtimeNote(rc)
      else if !o.current?
        o.deltaNote = o.emptyNote || 'Belum ada data di periode ini'
      else if !cmp
        o.deltaNote = if @days >= 730 then 'Tanpa pembanding untuk 2 tahun' else 'Tanpa pembanding'
      else
        d = @delta(o.current, o.previous, o.deltaKind, o.lowerBetter)
        if d
          o.deltaText = d.text
          o.deltaCls  = d.cls
          o.deltaVs   = "vs #{cmpLabel}"
        else
          o.deltaNote = "vs #{cmpLabel}: belum ada data"
      o

    list = [
      # FRT (Section 22.5, ikut rumus Reporting FRT): angka utama = median, mean
      # berdampingan + tanda outlier; status = % tiket sesuai target help
      # topic/grup/kanalnya (Section 20), dengan ambang Rasio Escalated.
      card(
        title: 'First Response Time', basis: basis, illus: 'frt'
        help: 'Median waktu dari tiket dibuat sampai respons pertama agent -- hanya tiket yang dibuka customer, dibuat di periode terpilih. Rumusnya sama dengan FRT di menu Reporting (median, jam kalender), tetapi tiket yang dibuat agent (FRT 0 menit) tidak dihitung. Live chat dihitung sejak customer memulai chat. Status = persen tiket yang respons pertamanya dalam target help topic-nya (Setting "Dasar target FRT"); live chat memakai target chat sendiri. Mean ditampilkan sebagai pembanding: jauh di atas median berarti ada outlier. Per agent: FRT milik agent yang pertama membalas.'
        value: frt.value, unit: frt.unit, emptyUnit: 'mnt', state: s.frt_target_state, n: s.frt_count, nLabel: 'tiket'
        emptyNote: 'Belum ada tiket customer yang direspons di periode ini'
        scaleKind: 'met', scaleKey: 'frt_target_met'
        current: s.frt_median_minutes, previous: cmp?.frt_median_minutes, deltaKind: 'duration', lowerBetter: true
        context: @frtContext(s, cmp)
        footLabel: 'Rata-rata (mean)', footValue: @fmtFrt(s.frt_mean_minutes, s.frt_time_basis), outlier: outlier
        drill: { metric: 'frt', label: 'Lihat tiket' }, drillCount: s.frt_count
      )
      card(
        title: 'CSAT', basis: basis, illus: 'csat'
        help: 'Rata-rata skor kepuasan pelanggan (1–5) dari rating yang masuk di periode terpilih. Dihitung menurut tanggal rating, bukan tanggal closed seperti laporan CSAT di Reporting, karena rating live chat masuk sebelum tiketnya closed.'
        value: @fmtNumber(s.csat_average, 2), unit: '/ 5', state: s.csat_state, n: s.csat_count, nLabel: 'rating'
        emptyNote: 'Belum ada rating di periode ini'
        scaleKind: 'csat', scaleKey: 'csat'
        current: s.csat_average, previous: cmp?.csat_average, deltaKind: 'score', lowerBetter: false
        footLabel: 'Rating masuk', footValue: @fmtNumber(s.csat_count, 0)
        coverage: @csatCoverage(s)
        drill: { metric: 'csat', label: 'Lihat rating' }, drillCount: s.csat_count
      )
      # status = % closed dalam batas SLA (close_escalation_at, kalender SLA
      # per help topic) -- rumus SLA SISKA, Section 22.6; median jam kalender.
      card(
        title: 'Waktu penyelesaian', basis: basis, illus: 'resolution'
        help: 'Median waktu dari tiket dibuat sampai pertama kali closed, untuk tiket yang closed di periode terpilih (jam kalender). Status = persen tiket closed dalam batas SLA penyelesaian help topic-nya (dihitung Zammad dengan kalender SLA), dengan ambang yang sama dengan Rasio Escalated.'
        value: res.value, unit: res.unit, emptyUnit: 'jam', state: s.sla_state, n: s.resolution_count, nLabel: 'closed'
        emptyNote: 'Belum ada tiket closed di periode ini'
        scaleKind: 'met', scaleKey: 'frt_target_met'
        current: s.resolution_median_minutes, previous: cmp?.resolution_median_minutes, deltaKind: 'duration', lowerBetter: true
        context: @slaContext(s, cmp)
        footLabel: 'Rata-rata (mean)', footValue: @fmtDurationText(s.resolution_mean_minutes)
        drill: { metric: 'resolution', label: 'Lihat tiket' }, drillCount: s.resolution_count
      )
      card(
        title: 'Reopening rate', basis: basis, illus: 'reopen'
        help: 'Persentase tiket yang dibuka ulang setelah closed, dari tiket yang closed di periode terpilih. Ambangnya sama dengan widget My Stats.'
        value: @fmtNumber(s.reopen_rate_percent, 1), unit: '%', emptyUnit: '%', state: s.reopen_state, n: s.reopen_closed_count, nLabel: 'closed'
        emptyNote: 'Belum ada tiket closed di periode ini'
        scaleKind: 'rate', scaleKey: 'reopen'
        current: s.reopen_rate_percent, previous: cmp?.reopen_rate_percent, deltaKind: 'rate', lowerBetter: true
        footLabel: 'Dibuka ulang', footValue: (if s.reopen_rate_percent? then "#{@fmtNumber(s.reopen_count, 0)} dari #{@fmtNumber(s.reopen_closed_count, 0)} tiket closed" else '—')
        drill: { metric: 'reopen', label: "Lihat #{@fmtNumber(s.reopen_count, 0)} tiket" }, drillCount: s.reopen_count
      )
      card(
        title: 'Rasio Escalated', basis: 'Real-time', live: true, illus: 'escalated'
        help: 'Tiket belum closed yang batas SLA-nya (escalation_at) sudah lewat, dibagi jumlah tiket New + Open. Real-time, tidak ikut filter periode. Delta dibanding snapshot per jam 24 jam lalu.'
        value: @fmtNumber(s.escalation_rate_percent, 1), unit: '%', emptyUnit: '%', state: s.escalated_state, n: active, nLabel: 'tiket'
        emptyNote: 'Tidak ada tiket New/Open saat ini'
        current: s.escalation_rate_percent, previous: rc?.escalation_rate_percent, deltaKind: 'rate'
        scaleKind: 'rate', scaleKey: 'escalated'
        footLabel: 'Lewat SLA', footValue: (if s.escalation_rate_percent? then "#{@fmtNumber(s.ticket_escalated, 0)} dari #{@fmtNumber(active, 0)} tiket New + Open" else '—')
        drill: { metric: 'escalated', label: "Lihat #{@fmtNumber(s.ticket_escalated, 0)} tiket" }, drillCount: s.ticket_escalated
      )
      card(
        title: 'Breach eskalasi', basis: 'Real-time', live: true, illus: 'breach'
        help: 'Tiket berstatus Eskalasi yang melewati batas waktu eskalasi (escalation_deadline_at). Status dihitung dari persentasenya terhadap tiket Eskalasi aktif. Real-time; delta dibanding snapshot per jam 24 jam lalu.'
        value: @fmtNumber(s.eskalasi_breach_rate_percent, 1), unit: '%', emptyUnit: '%', state: s.eskalasi_breach_state, n: s.eskalasi_active, nLabel: 'eskalasi'
        current: s.eskalasi_breach_rate_percent, previous: rc?.eskalasi_breach_rate_percent, deltaKind: 'rate'
        scaleKind: 'rate', scaleKey: 'eskalasi_breach'
        footLabel: 'Lewat batas', footValue: "#{@fmtNumber(s.eskalasi_breached, 0)} dari #{@fmtNumber(s.eskalasi_active, 0)} eskalasi aktif"
        drill: { metric: 'breach', label: "Lihat #{@fmtNumber(s.eskalasi_breached, 0)} tiket" }, drillCount: s.eskalasi_breached
      )
    ]
    @pickCards(list, s, card, basis)

  # Turunan (KPI Saya) memilih/menambah kartu dengan pembangun kartu yang sama.
  pickCards: (list) ->
    list

  # ------------------------------------------------------------- grafik

  fmtMetric: (v, kind) =>
    return '—' if !v?
    switch kind
      when 'duration' then @fmtDurationText(v)
      when 'score'    then @fmtNumber(v, 2)
      when 'rate'     then "#{@fmtNumber(v, 1)}%"
      else                 @fmtNumber(v, 0)

  # Data untuk ApexCharts line (drawTrend); ringkasan rata-rata + delta di
  # atas grafik tetap dihitung di sini.
  trendView: (trend, failed, loading) =>
    metric = _.find(@METRICS, (m) => m.key is @metric)
    metrics = for m in @METRICS
      { key: m.key, label: m.label, active: m.key is @metric }
    view = { metrics: metrics, metricLabel: metric.label, empty: true, emptyText: 'Memuat…' }
    if failed
      view.emptyText = 'Gagal memuat grafik. Coba lagi beberapa saat lagi.'
      return view
    # data metrik/filter lain (sesaat setelah ganti) tidak ditampilkan
    return view if loading || !trend || !trend.points || trend.metric isnt @metric

    cur  = _.map(trend.points, (p) -> p.value)
    prev = if trend.comparison then _.map(trend.comparison.points, (p) -> p.value) else []
    if !_.some(cur, (v) -> v?) || (metric.kind is 'count' && !_.some(cur, (v) -> v > 0))
      view.emptyText = if trend.unavailable is 'filters'
        'Rasio Escalated tidak tersedia dengan filter ini (snapshot hanya dipisah per grup).'
      else if metric.key is 'escalated' && trend.history_since
        "Snapshot Rasio Escalated baru dikumpulkan sejak #{@fmtDateTime(trend.history_since)}; tren muncul setelah beberapa jam."
      else if metric.key is 'escalated'
        'Snapshot Rasio Escalated belum dikumpulkan.'
      else
        'Belum ada data untuk periode dan filter ini.'
      return view

    avg = (series) ->
      xs = _.filter(series, (v) -> v?)
      return null if !xs.length
      _.reduce(xs, ((a, b) -> a + b), 0) / xs.length
    curAvg  = avg(cur)
    prevAvg = if trend.comparison then avg(prev) else null
    d = @delta(curAvg, prevAvg, metric.kind, metric.lowerBetter)

    cats = for p in trend.points
      if trend.bucket is 'month'
        date = new Date("#{p.bucket_start}T00:00:00")
        "#{@MONTHS[date.getMonth()]} #{String(date.getFullYear()).substr(2)}"
      else
        @fmtDate(p.bucket_start)
    bucketName = { day: 'hari', week: 'minggu', month: 'bulan' }[trend.bucket]
    subtitle = "#{metric.label} per #{bucketName} · #{@fmtRange(trend.period)}"
    subtitle += " vs #{@fmtRange(trend.comparison.period)}" if trend.comparison
    cmpLabel = if trend.comparison?.mode is 'yoy' then 'Tahun lalu' else 'Periode sebelumnya'

    _.extend(view,
      empty:    false
      subtitle: subtitle
      hasCmp:   !!trend.comparison
      cmpLabel: cmpLabel
      curAvg:   @fmtMetric(curAvg, metric.kind)
      prevAvg:  @fmtMetric(prevAvg, metric.kind)
      delta:    d
      chart:
        kind:     metric.kind
        cats:     cats
        cur:      cur
        # deret pembanding disejajarkan per bucket (backend menyamakan jumlahnya)
        prev:     if trend.comparison then _.first(prev.concat(_.map(cur, -> null)), cur.length) else null
        cmpLabel: cmpLabel
        bucket:   { day: 'Hari', week: 'Minggu mulai', month: 'Bulan' }[trend.bucket]
    )

  # Seri untuk ApexCharts heatmap (drawHeatmap): satu seri per hari,
  # seri pertama digambar paling bawah -> Minggu dulu supaya Senin di atas.
  heatmapView: (heatmap, failed, loading) =>
    return { state: 'failed' } if failed
    return { state: 'loading' } if loading || !heatmap || !heatmap.cells
    max = heatmap.max_avg || 0
    return { state: 'empty' } if max <= 0
    byKey = {}
    byKey["#{c.dow}-#{c.hour}"] = c for c in heatmap.cells
    series = for dow in [7..1]
      data = for hour in [0..23]
        c = byKey["#{dow}-#{hour}"] || { avg_per_day: 0, total: 0 }
        { x: @pad2(hour), y: c.avg_per_day, total: c.total }
      { name: @WEEKDAYS[dow - 1].substr(0, 3), full: @WEEKDAYS[dow - 1], data: data }
    { state: 'ready', series: series, max: @fmtNumber(max, 1), summary: @heatmapSummary(heatmap.cells, heatmap.business_hours) }

  # Ringkasan pola beban di bawah grid (untuk jadwal shift). Jam kerja =
  # Senin-Jumat 08.00-16.59 (asumsi; bukan dari Setting/kalender SLA).
  heatmapSummary: (cells, bh) =>
    return null if !cells || !_.some(cells, (c) -> c.total > 0)
    top = _.max(cells, (c) -> c.avg_per_day)
    byDay = _.map([1..7], (dow) -> { dow: dow, avg: _.reduce(_.filter(cells, (c) -> c.dow is dow), ((s, c) -> s + c.avg_per_day), 0) })
    day = _.max(byDay, (d) -> d.avg)
    byHour = _.map([0..23], (h) -> { hour: h, avg: _.reduce(_.filter(cells, (c) -> c.hour is h), ((s, c) -> s + c.avg_per_day), 0) / 7 })
    hour = _.max(byHour, (h) -> h.avg)
    total = _.reduce(cells, ((s, c) -> s + c.total), 0)
    # jam kerja dari kalender default SISKA (heatmap.business_hours, Section 22.6)
    isWork = (c) ->
      return c.dow <= 5 && c.hour >= 8 && c.hour < 17 if !bh
      _.some(bh.days[c.dow] || [], (f) -> c.hour >= Math.floor(f[0]) && c.hour < f[1])
    outside = _.reduce(_.filter(cells, (c) -> !isWork(c)), ((s, c) -> s + c.total), 0)
    [
      { label: 'Jam tersibuk',     value: "#{@WEEKDAYS[top.dow - 1]} #{@pad2(top.hour)}.00", note: "#{@fmtNumber(top.avg_per_day, 1)} tiket/hari" }
      { label: 'Hari tersibuk',    value: @WEEKDAYS[day.dow - 1], note: "#{@fmtNumber(day.avg, 1)} tiket/hari" }
      { label: 'Jam paling ramai', value: "#{@pad2(hour.hour)}.00–#{@pad2(hour.hour)}.59", note: "rata-rata #{@fmtNumber(hour.avg, 1)} tiket/hari" }
      { label: 'Di luar jam kerja', value: "#{@fmtNumber(outside / total * 100, 1)}%", note: "#{@fmtNumber(outside, 0)} dari #{@fmtNumber(total, 0)} tiket", note2: @businessHoursText(bh) }
    ]

  SLA_MAX_ROWS: 3

  # Angka utama kartu SLA: semua prioritas (sla_* dari /team_kpi) dalam format
  # persen kit (tepat waktu + % + perubahan vs pembanding), lalu terlambat /
  # median keterlambatan.
  slaTotal: (s) =>
    return null if !s.sla_total
    cmp = s.comparison
    # warna = ambang Rasio Escalated atas % terlambat, sama dengan status kartu (Section 23)
    cls = @metCls(s.sla_within_percent)
    deltaVs = if cmp?.mode is 'yoy' then 'vs tahun lalu, periode sama' else 'vs periode sebelumnya'
    {
      pctHtml:   @pctView(
        count: s.sla_within, pct: s.sla_within_percent, tone: { good: 'success', ok: 'warning', bad: 'danger' }[cls]
        prev: cmp?.sla_within_percent, lowerBetter: false, vs: deltaVs
        note: (if !cmp then (if @days >= 730 then 'Tanpa pembanding untuk 2 tahun' else 'Tanpa pembanding') else 'Pembanding belum ada data')
        baseLabel: 'Closed tepat waktu dari', baseCount: s.sla_total, baseUnit: 'tiket'
        badgeTip: 'SLA penyelesaian (tepat waktu)'
      )
      late:      @fmtNumber(s.sla_late, 0)
      lateHot:   s.sla_late > 0
      lateMed:   @fmtDurationText(s.sla_late_median_minutes)
    }

  # SLA per help topic (Section 22.6, dimensi SLA SISKA): topik dengan
  # n >= SMALL_SAMPLE diurutkan dari % tepat waktu terendah (paling perlu
  # perhatian), maks. SLA_MAX_ROWS; sisanya di tooltip "lainnya".
  slaView: (s) =>
    all  = s.sla_by_help_topic || []
    big  = _.sortBy(_.filter(all, (r) => r.total >= @SMALL_SAMPLE), (r) -> if r.within_percent? then r.within_percent else 101)
    rows = big.slice(0, @SLA_MAX_ROWS)
    rest = _.difference(all, rows)
    label = (r) -> r.help_topic || '(tanpa help topic)'
    shown = for row in rows
      pct = row.within_percent
      {
        label: label(row), target: (if row.target_minutes? then "target #{@fmtWorkDuration(row.target_minutes)}" else null)
        pct: (if pct? then pct else 0), pctText: (if pct? then "#{@fmtNumber(pct, 1)}%" else '—'), total: @fmtNumber(row.total, 0), late: @fmtNumber(row.late, 0), cls: @metCls(pct)
      }
    {
      rows: shown
      more: if rest.length then "+#{rest.length} help topic lain" else null
      moreTip: _.map(rest, (r) => "#{label(r)}: #{if r.within_percent? then @fmtNumber(r.within_percent, 1) + '%' else '—'} (n #{@fmtNumber(r.total, 0)})").join(' · ')
    }

  # FRT per help topic (Section 23). Ringkasan di tab SLA & Backlog: angka
  # tim (= kartu FRT) + help topic n >= SMALL_SAMPLE dengan % sesuai target
  # terendah, maks. SLA_MAX_ROWS -- pola yang sama dengan SLA per help topic.
  topicTargetText: (row, s) =>
    return 'target campuran' if !row.target_minutes?
    text = "target #{@fmtFrt(row.target_minutes, s.frt_time_basis)}"
    text += ' (global)' if s.frt_target_basis is 'help_topic' && !row.own_target
    text

  frtTopicView: (s) =>
    return null if !s.frt_count
    cmp = s.comparison
    cls = @metCls(s.frt_target_met_percent)
    all = s.frt_by_help_topic || []
    big = _.sortBy(_.filter(all, (r) => r.count >= @SMALL_SAMPLE && r.target_met_percent?), (r) -> r.target_met_percent)
    rows = big.slice(0, @SLA_MAX_ROWS)
    late = s.frt_count - (s.frt_target_met_count || 0)
    {
      pctHtml: @pctView(
        count: s.frt_target_met_count, pct: s.frt_target_met_percent, tone: { good: 'success', ok: 'warning', bad: 'danger' }[cls]
        prev: cmp?.frt_target_met_percent, lowerBetter: false, vs: (if cmp?.mode is 'yoy' then 'vs tahun lalu, periode sama' else 'vs periode sebelumnya')
        note: (if !cmp then (if @days >= 730 then 'Tanpa pembanding untuk 2 tahun' else 'Tanpa pembanding') else 'Pembanding belum ada data')
        baseLabel: 'Sesuai target dari', baseCount: s.frt_count, baseUnit: 'tiket'
        badgeTip: 'FRT sesuai target'
      )
      late:    @fmtNumber(late, 0)
      lateHot: late > 0
      globalCount: if s.frt_target_basis is 'help_topic' then @fmtNumber(_.filter(all, (r) -> !r.own_target).length, 0) else null
      rows: for row in rows
        {
          label: row.help_topic || '(tanpa help topic)', target: @topicTargetText(row, s)
          total: @fmtNumber(row.count, 0), late: @fmtNumber(row.count - row.target_met_count, 0)
          pct: row.target_met_percent, pctText: "#{@fmtNumber(row.target_met_percent, 1)}%", cls: @metCls(row.target_met_percent)
        }
      more: if all.length > rows.length then "+#{all.length - rows.length} help topic lain" else null
      moreTip: _.map(_.difference(all, rows), (r) => "#{r.help_topic || '(tanpa help topic)'}: #{if r.target_met_percent? then @fmtNumber(r.target_met_percent, 1) + '%' else '—'} (n #{@fmtNumber(r.count, 0)})").join(' · ')
    }

  TOPIC_SORTS: [
    { value: 'count', label: 'Tiket terbanyak' }
    { value: 'met',   label: '% sesuai target terendah' }
    { value: 'name',  label: 'Nama help topic' }
  ]

  # Sub-tab Per help topic: satu baris per help topic (gabungan FRT dan SLA
  # penyelesaian). Topik dengan n < SMALL_SAMPLE di kedua metrik disembunyikan
  # sampai diminta; help topic ber-n besar yang masih memakai target global
  # ditandai (tindak lanjut Section 22.3).
  topicView: (s) =>
    frt  = s.frt_by_help_topic || []
    sla  = s.sla_by_help_topic || []
    name = (r) -> r.help_topic || ''
    fmap = _.indexBy(frt, name)
    smap = _.indexBy(sla, name)
    basisTopic = s.frt_target_basis is 'help_topic'
    delta = (f) =>
      return null if f.count < @SMALL_SAMPLE || !(f.prev_count >= @SMALL_SAMPLE) || !f.prev_target_met_percent? || !f.target_met_percent?
      d = f.target_met_percent - f.prev_target_met_percent
      return { text: '= sama', cls: 'is-flat' } if Math.abs(d) < 0.05
      { text: "#{if d > 0 then '▲' else '▼'} #{@fmtNumber(Math.abs(d), 1)}", cls: if d > 0 then 'is-better' else 'is-worse' }
    rows = for key in _.uniq(_.map(frt, name).concat(_.map(sla, name)))
      f = fmap[key]
      q = smap[key]
      {
        label: key || '(tanpa help topic)'
        big:   (f?.count >= @SMALL_SAMPLE) || (q?.total >= @SMALL_SAMPLE)
        count: f?.count || 0
        slaTotal: q?.total || 0
        met:   if f?.target_met_percent? then f.target_met_percent else 101
        frt: if f then {
          target: (if f.target_minutes? then @fmtFrt(f.target_minutes, s.frt_time_basis) else 'campuran')
          global: basisTopic && !f.own_target
          n: @fmtNumber(f.count, 0), small: f.count < @SMALL_SAMPLE
          median: @fmtFrt(f.median_minutes, s.frt_time_basis)
          pct: f.target_met_percent || 0, pctText: (if f.target_met_percent? then "#{@fmtNumber(f.target_met_percent, 1)}%" else '—'), cls: @metCls(f.target_met_percent)
          delta: delta(f)
        } else null
        sla: if q then {
          target: (if q.target_minutes? then @fmtWorkDuration(q.target_minutes) else '—')
          n: @fmtNumber(q.total, 0), small: q.total < @SMALL_SAMPLE
          pct: q.within_percent || 0, pctText: (if q.within_percent? then "#{@fmtNumber(q.within_percent, 1)}%" else '—'), cls: @metCls(q.within_percent)
        } else null
      }
    rows = switch @topicSort
      when 'met'  then rows.sort((a, b) -> (a.met - b.met) || (b.count - a.count))
      when 'name' then _.sortBy(rows, (r) -> r.label.toLowerCase())
      else             rows.sort((a, b) -> (b.count - a.count) || (b.slaTotal - a.slaTotal))
    bigRows = _.filter(rows, (r) -> r.big)
    globalBig = if basisTopic then _.filter(frt, (r) => r.count >= @SMALL_SAMPLE && !r.own_target) else []
    targetSource = switch s.frt_target_basis
      when 'group'   then 'Target FRT per grup (Admin › Groups)'
      when 'channel' then 'Target FRT per kanal (Setting)'
      else                'Target FRT dari Setting "Target FRT per help topic"'
    {
      empty:      !rows.length
      rows:       if @topicSmall then rows else bigRows
      smallCount: rows.length - bigRows.length
      showSmall:  @topicSmall
      sorts:      ({ value: o.value, label: o.label, selected: o.value is @topicSort } for o in @TOPIC_SORTS)
      note:       "#{targetSource}#{if s.frt_time_basis is 'business' then ' (jam kerja)' else ''} · target SLA = waktu penyelesaian SLA topik (1 hari kerja = 9 jam) · #{@periodLabel()}"
      alert: if globalBig.length then {
        head: "#{globalBig.length} help topic sudah ≥ #{@SMALL_SAMPLE} tiket tapi masih memakai target global #{@fmtFrt(_.first(globalBig).target_minutes, s.frt_time_basis)}:"
        list: _.map(globalBig, (r) => "#{r.help_topic || '(tanpa help topic)'} (#{@fmtNumber(r.count, 0)} tiket, #{@fmtNumber(r.target_met_percent, 1)}%)").join(', ')
      } else null
    }

  backlogView: (s) =>
    rows = s.backlog_aging || []
    max  = _.max(_.map(rows, (r) -> r.count).concat([1]))
    for row, i in rows
      { label: @BACKLOG_LABELS[row.bucket] || row.bucket, count: @fmtNumber(row.count, 0), pct: Math.round(row.count / max * 100), old: i >= 3 }

  # Warna sel % sesuai target di tabel agent: Sangat baik/Baik = hijau,
  # Cukup = oranye, Buruk/Sangat buruk = merah (ambang Section 22.4).
  metCls: (pct) =>
    t = @data.summary?.thresholds?.frt_target_met
    return 'none' if !pct? || !t
    if pct > t.good_above then 'good' else if pct > t.ok_above then 'ok' else 'bad'

  agentsView: (agents) =>
    return null if !@canSeeAgents || !agents || !agents.agents
    rows = _.filter(agents.agents, (a) -> a.tickets > 0 || a.escalated > 0 || a.frt_count > 0)
    max  = _.max(_.map(rows, (a) -> a.tickets).concat([1]))
    for a in rows.slice(0, 12)
      name = if a.unassigned then 'Belum ditugaskan' else (a.name || '—')
      initials = if a.unassigned then '—' else _.map(name.split(/\s+/).slice(0, 2), (w) -> w.charAt(0).toUpperCase()).join('')
      csatCls = if !a.csat_average? then 'none' else if a.csat_average >= 4 then 'good' else if a.csat_average >= 3 then 'ok' else 'bad'
      {
        name: name, initials: initials, unassigned: a.unassigned
        tickets: @fmtNumber(a.tickets, 0), pct: Math.round(a.tickets / max * 100)
        frt: @fmtFrt(a.frt_median_minutes), frtCls: @metCls(a.frt_target_met_percent)
        frtTip: "Mean #{@fmtFrt(a.frt_mean_minutes)} · #{if a.frt_target_met_percent? then @fmtNumber(a.frt_target_met_percent, 1) + '%' else '—'} sesuai target (#{a.frt_target_met_count || 0} dari #{a.frt_count} tiket, pembalas pertama)#{if @data.summary?.frt_time_basis is 'business' then ' · jam kerja' else ''}"
        csat: @fmtNumber(a.csat_average, 2), csatTip: "n #{a.csat_count} rating", csatCls: csatCls
        escalated: @fmtNumber(a.escalated, 0), breach: @fmtNumber(a.eskalasi_breached, 0), breachHot: a.eskalasi_breached > 0
      }

  # Opsi multi-select dari /team_kpi/filter_options (jumlah tiket di periode &
  # grup terpilih). Pilihan yang sedang aktif tetap ada walau datanya belum
  # dimuat / tidak ada di periode ini.
  multiFiltersView: =>
    opts = @data.options || {}
    for f in @MULTI_FILTERS
      selected = @filters[f.key]
      options = for o in (opts[f.source] || [])
        value = String(o.id ? o.value ? o.name)
        { value: value, label: o.label || o.name, count: @fmtNumber(o.count, 0), selected: _.contains(selected, value) }
      known = _.pluck(options, 'value')
      for v in selected when !_.contains(known, v)
        options.push({ value: v, label: v, count: null, selected: true })
      { key: f.key, label: f.label, placeholder: f.placeholder, options: options }

  groupOptions: =>
    ids = _.map(App.User.current()?.allGroupIds('read') || [], (id) -> parseInt(id, 10))
    groups = _.filter(App.Group.all(), (g) -> g.active && _.contains(ids, g.id))
    _.sortBy(_.map(groups, (g) => { id: g.id, name: g.name, selected: "#{g.id}" is "#{@groupId}" }), 'name')

  # ------------------------------------------------------------- render

  # Badge di label tab (pola kit invoice-list: badge -500/10 rounded-full):
  # SLA & Backlog = merah (% SLA) kalau status SLA di bawah Baik, oranye (jumlah) kalau ada
  # backlog >= 30 hari; Per agent = jumlah agent aktif (agents_active_count).
  tabsView: (s) =>
    slaBadge = null
    if s
      old = _.find(s.backlog_aging || [], (b) -> b.bucket is 'gte_30d')
      # ambang Rasio Escalated atas % terlambat, sama dengan status kartu (Section 23)
      if s.sla_total && s.sla_within_percent? && @metCls(s.sla_within_percent) in ['ok', 'bad']
        slaBadge = { text: "#{@fmtNumber(s.sla_within_percent, 1)}%", cls: 'is-danger', tip: "SLA penyelesaian #{@fmtNumber(s.sla_within_percent, 1)}% (#{@STATE_LABELS[s.sla_state] || 'di bawah Baik'})" }
      else if old?.count > 0
        slaBadge = { text: @fmtNumber(old.count, 0), cls: 'is-warning', tip: "#{@fmtNumber(old.count, 0)} tiket backlog berumur ≥ 30 hari" }
    # dari ringkasan (agents_active_count, hanya team_kpi.agents/admin), jadi tampil
    # tanpa harus memuat tabel agent dulu
    agentsBadge = null
    if s?.agents_active_count > 0
      n = s.agents_active_count
      agentsBadge = { text: @fmtNumber(n, 0), cls: 'is-primary', tip: "#{@fmtNumber(n, 0)} agent aktif di periode ini" }
    for t in @availableTabs()
      badge = if t.key is 'sla' then slaBadge else if t.key is 'agents' then agentsBadge else null
      { key: t.key, label: t.label, active: t.key is @tab, badge: badge }

  render: =>
    s = @data.summary
    failed = @failed || []
    periods = for p in @PERIODS
      { days: p.days, label: p.label, active: p.days is @days }
    partFailed  = (part) => !@loading && _.contains(failed, part) && !@hasPart(part)
    partLoading = (part) => !@hasPart(part) && !partFailed(part)

    view =
      loading:      @loading && !s
      refreshing:   @loading && !!s
      periods:      periods
      groups:       @groupOptions()
      canSeeAgents: @canSeeAgents
      updatedAt:    @fmtTime(@fetchedAt)
      stale:        !@loading && failed.length > 0 && !!s
      failedAll:    !@loading && failed.length > 0 && !s
      summary:      !!s
      tab:          @tab
      tabs:         @tabsView(s)
      compares:     ({ value: c.value, label: c.label, selected: c.value is @compare } for c in @COMPARES)
      multiFilters: @multiFiltersView()
      hasFilters:   @hasFilters()
      kpiName:      @KPI_NAME

    if s
      total = (s.ticket_new || 0) + (s.ticket_open || 0)
      rc = s.realtime_comparison
      queueDelta = (now, past) =>
        return null if !rc?.available || !past?
        diff = now - past
        return { text: 'sama', cls: 'is-flat' } if diff is 0
        { text: "#{if diff > 0 then '▲' else '▼'} #{@fmtNumber(Math.abs(diff), 0)}", cls: if diff > 0 then 'is-worse' else 'is-better' }
      _.extend(view,
        cmpRange:  if s.comparison then "#{@fmtRange(s.comparison)}#{if s.comparison.mode is 'yoy' then ' (tahun lalu)' else ''}" else null
        noCmpNote: if @days >= 730 then 'Tanpa pembanding untuk 2 tahun' else 'Tanpa pembanding'
        basis:     @periodLabel()
        periodRange: @fmtRange(s.period)
        cards:     @cards(s)
        queue:
          total:     @fmtNumber(total, 0)
          new:       @fmtNumber(s.ticket_new, 0)
          open:      @fmtNumber(s.ticket_open, 0)
          escalated: @fmtNumber(s.ticket_escalated, 0)
          note:      if rc?.available then "Tidak ikut filter periode · ▲▼ vs kemarin (snapshot #{@fmtDateTime(rc.captured_at)})" else 'Tidak ikut filter periode'
          dTotal:    queueDelta(total, if rc?.available then (rc.ticket_new || 0) + (rc.ticket_open || 0) else null)
          dNew:      queueDelta(s.ticket_new, rc?.ticket_new)
          dOpen:     queueDelta(s.ticket_open, rc?.ticket_open)
          dEsc:      queueDelta(s.ticket_escalated, rc?.ticket_escalated)
          newPct:    @fmtNumber((s.ticket_new || 0) / Math.max(total, 1) * 100, 1)
          openPct:   @fmtNumber((s.ticket_open || 0) / Math.max(total, 1) * 100, 1)
        sla:       @slaView(s)
        frtTopic:  @frtTopicView(s)
        slaTotal:  @slaTotal(s)
        backlog:   @backlogView(s)
      )
      @extendView(view, s, partFailed, partLoading)
      switch @tab
        when 'trend'  then view.trend   = @trendView(@data.trend, partFailed('trend'), partLoading('trend'))
        when 'load'   then view.heatmap = @heatmapView(@data.heatmap, partFailed('heatmap'), partLoading('heatmap'))
        when 'topic'  then view.topic   = @topicView(s)
        when 'agents'
          view.agentsState = if partFailed('agents') then 'failed' else if partLoading('agents') then 'loading' else 'ready'
          view.agents = @agentsView(@data.agents) if view.agentsState is 'ready'
          # tabel dibatasi 12 baris; badge tab menghitung semua agent aktif
          shown = _.filter(view.agents || [], (a) -> !a.unassigned).length
          if s.agents_active_count > shown && shown > 0
            view.agentsMore = "Menampilkan #{shown} agent teratas dari #{@fmtNumber(s.agents_active_count, 0)} · urut jumlah tiket"

    # Tab dirender ulang tiap memuat; radio Periode yang sedang difokus
    # (panah kiri/kanan) difokuskan lagi supaya navigasi keyboard tidak putus.
    periodFocused = $(document.activeElement).is('.js-kpi-period') && $.contains(@el[0], document.activeElement)
    # sama untuk kontrol sub-tab Per help topic (urutan, tampilkan topik kecil)
    topicFocus = _.find(['.js-kpi-topic-sort', '.js-kpi-topic-small'], (sel) => $(document.activeElement).is(sel) && $.contains(@el[0], document.activeElement))
    @destroyCharts()
    @destroyChoices()
    @html App.view('dashboard/team_kpi')(view)
    @$('.js-kpi-period:checked').trigger('focus') if periodFocused
    @$(topicFocus).trigger('focus') if topicFocus
    @$('.js-kpi-tip').tooltip(container: 'body')
    @drawCharts(view)
    @initChoices()

  # Tambahan view untuk turunan (KPI Saya); KPI Tim tidak menambah apa pun.
  extendView: ->

  # ------------------------------------------------------------- ApexCharts

  # Dimuat sekali per halaman (bukan bagian application.js); callback yang
  # menunggu dijalankan setelah skrip siap. Dipakai ApexCharts & Choices.js.
  @scriptQueues: {}
  loadScript: (url, globalName, callback) =>
    return callback() if window[globalName]
    queues = App.DashboardTeamKpi.scriptQueues
    if queues[globalName]
      queues[globalName].push(callback)
      return
    queues[globalName] = [callback]
    script = document.createElement('script')
    script.src = url
    script.async = true
    script.onload = ->
      queue = queues[globalName] || []
      delete queues[globalName]
      cb() for cb in queue
    script.onerror = ->
      delete queues[globalName]
      App.Log.error('DashboardTeamKpi', "#{globalName} gagal dimuat")
    document.head.appendChild(script)

  loadApex: (callback) =>
    @loadScript(@APEX_URL, 'ApexCharts', callback)

  # Multi-select gaya kit (forms/form2_choices.html): chip terpilih di dalam
  # kolom, jumlah tiket per opsi lewat data-label-description (hanya tampil di
  # daftar pilihan). Sebelum skrip siap, <select multiple> asli tetap berfungsi.
  initChoices: =>
    return if !@$('.js-kpi-multi').length
    @loadScript(@CHOICES_URL, 'Choices', =>
      @$('.js-kpi-multi').each((i, el) =>
        return if !document.body.contains(el) || el.dataset.choice
        @choices.push(new window.Choices(el,
          removeItemButton:    true
          shouldSort:          false
          searchEnabled:       false
          placeholder:         true
          placeholderValue:    el.dataset.placeholder
          itemSelectText:      ''
          noChoicesText:       App.i18n?.translateInline?('Semua pilihan sudah dipilih') || 'Semua pilihan sudah dipilih'
          removeItemIconText:  -> 'Hapus'
          removeItemLabelText: (value) -> "Hapus #{value}"
          allowHTML:           false
        ))
      )
    )

  destroyChoices: =>
    for c in @choices || []
      try c.destroy()
    @choices = []

  destroyCharts: =>
    for name, chart of @charts || {}
      try chart.destroy()
    @charts = {}

  drawCharts: (view) =>
    trendEl = @$('.js-kpi-trend-chart').get(0)
    heatEl  = @$('.js-kpi-heat-chart').get(0)
    return if !trendEl && !heatEl
    @loadApex =>
      # render ulang sebelum skrip selesai dimuat -> elemen lama sudah lepas
      @drawTrend(trendEl, view.trend.chart) if trendEl && document.body.contains(trendEl)
      @drawHeatmap(heatEl, view.heatmap) if heatEl && document.body.contains(heatEl)

  # Gaya kit line-chart-3: garis pembanding putus-putus (stroke.dashArray),
  # tooltip gabungan per titik.
  drawTrend: (el, t) =>
    few = _.filter(t.cur, (v) -> v?).length <= 2
    fmt = (v) => @fmtMetric(v, t.kind)
    series = [{ name: 'Periode ini', data: t.cur }]
    series.push({ name: t.cmpLabel, data: t.prev }) if t.prev
    colors = ['#4680ff', '#5b6b79']
    # titik tanpa tetangga (hari sebelum & sesudahnya kosong) tidak punya garis,
    # jadi nyaris tak terlihat padahal ikut menentukan skala -- beri penanda
    discrete = []
    for s, si in series
      for v, i in s.data when v? and !s.data[i - 1]? and !s.data[i + 1]?
        discrete.push({ seriesIndex: si, dataPointIndex: i, fillColor: (if si is 0 then colors[0] else '#ffffff'), strokeColor: colors[si], size: 4 })
    @charts.trend = new ApexCharts(el,
      chart:      { type: 'line', height: 300, fontFamily: 'inherit', toolbar: { show: false }, zoom: { enabled: false }, animations: { enabled: false } }
      series:     series
      colors:     colors
      stroke:     { width: [2.5, 1.5], curve: 'straight', dashArray: [0, 5] }
      markers:    { size: (if few then 5 else 0), discrete: (if few then [] else discrete), hover: { sizeOffset: 6 } }
      dataLabels: { enabled: false }
      legend:     { show: false }
      grid:       { borderColor: '#e7eaee', strokeDashArray: 0, padding: { left: 8, right: 8 } }
      xaxis:
        categories: t.cats
        tickAmount: Math.min(t.cats.length - 1, 8)
        labels:     { rotate: 0, hideOverlappingLabels: true, style: { colors: '#5b6b79', fontSize: '11px' } }
        axisBorder: { color: '#bec8d0' }
        axisTicks:  { show: false }
        tooltip:    { enabled: false }
      yaxis:
        min: 0
        forceNiceScale: true
        labels: { style: { colors: '#5b6b79', fontSize: '11px' }, formatter: fmt }
      tooltip:
        shared: true
        intersect: false
        x: { formatter: (v, o) -> "#{t.bucket} #{t.cats[o.dataPointIndex]}" }
        y: { formatter: fmt }
    )
    @charts.trend.render()

  # Gaya kit heatmap-chart-1: satu warna #4680ff, shade otomatis, tanpa label.
  drawHeatmap: (el, h) =>
    avg = (v) => @fmtNumber(v, 1)
    @charts.heatmap = new ApexCharts(el,
      chart:       { type: 'heatmap', height: 380, fontFamily: 'inherit', toolbar: { show: false }, animations: { enabled: false } }
      series:      _.map(h.series, (s) -> { name: s.name, data: s.data })
      colors:      ['#4680ff']
      dataLabels:  { enabled: false }
      stroke:      { width: 3, colors: ['#ffffff'] }
      plotOptions: { heatmap: { radius: 4 } }
      legend:      { show: false }
      xaxis:
        labels:     { style: { colors: '#5b6b79', fontSize: '11px' }, formatter: (v) -> if parseInt(v, 10) % 3 is 0 then v else '' }
        axisBorder: { show: false }
        axisTicks:  { show: false }
        tooltip:    { enabled: false }
      yaxis:
        labels: { style: { colors: '#5b6b79', fontSize: '12px' } }
      tooltip:
        custom: (o) ->
          s = h.series[o.seriesIndex]
          d = s.data[o.dataPointIndex]
          "<div class=\"team-kpi-apex-tip\"><b>#{s.full} #{d.x}.00–#{d.x}.59</b><br>Rata-rata #{avg(d.y)} tiket/hari · total #{d.total}</div>"
    )
    @charts.heatmap.render()

# Drill-down kartu KPI Tim (Section 18, artboard TeamKpi-QuickWin-States):
# modal-lg gaya kit (modal.css) berisi table-hover daftar tiket di balik
# angka kartu -- periode & filter sama dengan dashboard, 50 teratas.
# "Ekspor daftar" = CSV sampai 5.000 baris; "Buka di pencarian" = 50 nomor
# yang tampil di pencarian Zammad.
class App.DashboardTeamKpiDrill extends App.ControllerModal
  large: true
  includeForm: false
  buttonSubmit: 'Ekspor daftar'
  buttonClass: 'btn--primary'
  leftButtons: [{ text: 'Buka di pencarian', className: 'js-kpi-drill-search' }]
  className: 'modal fade team-kpi-modal'
  autoFocusOnFirstInput: false

  events: _.extend({}, App.ControllerModal::events,
    'click .js-kpi-drill-search': 'onSearch'
    'click .js-kpi-drill-ticket': 'onTicket'
  )

  # at = kolom tanggal, col/kind = kolom nilai (null = tanpa kolom nilai)
  METRICS:
    frt:        { title: 'Tiket FRT',                 at: 'Dibuat',          col: 'FRT',          kind: 'duration', order: 'terlama direspons' }
    csat:       { title: 'Rating CSAT',               at: 'Dinilai',         col: 'Skor',         kind: 'score',    order: 'terbaru' }
    resolution: { title: 'Tiket closed',              at: 'Closed',          col: 'Penyelesaian', kind: 'duration', order: 'terlama selesai' }
    reopen:     { title: 'Tiket dibuka ulang',        at: 'Dibuka ulang',    col: null,           kind: null,       order: 'terbaru dibuka ulang' }
    escalated:  { title: 'Tiket lewat SLA',           at: 'Lewat SLA sejak', col: null,           kind: null,       order: 'paling lama lewat SLA' }
    breach:     { title: 'Eskalasi lewat batas waktu', at: 'Batas eskalasi', col: null,           kind: null,       order: 'paling lama lewat batas' }

  constructor: (params) ->
    @def    = App.DashboardTeamKpiDrill::METRICS[params.metric]
    @head   = @def.title
    @state  = 'loading'
    @query  = _.extend({}, params.kpi.params(), metric: params.metric)
    super
    @fetch()

  fetch: =>
    @ajax(
      id:          'team_kpi_drill'
      type:        'GET'
      url:         "#{@apiPath}/team_kpi/tickets"
      data:        _.extend({}, @query, limit: 50)
      processData: true
      success: (data) =>
        @result = data
        @state  = 'ready'
        @update()
      error: =>
        @state = 'failed'
        @update()
    )

  # Judul sudah di kepala modal; subjudul = konteks (periode/filter/urutan).
  subtitle: =>
    parts = [if @result?.realtime then 'Real-time' else @kpi.periodLabel()]
    parts = parts.concat(@kpi.filterSummary())
    parts.push("urut #{@def.order}")
    parts.join(' · ')

  content: =>
    kpi = @kpi
    rows = for t in @result?.tickets || []
      {
        id:     t.id
        number: t.number
        title:  t.title
        group:  t.group || '—'
        owner:  t.owner || 'Belum ditugaskan'
        at:     kpi.fmtDateTimeYear(t.at)
        value:  if @def.col then kpi.fmtMetric(t.value, @def.kind) else null
      }
    total = @result?.total || 0
    App.view('dashboard/team_kpi_drill')(
      state:    @state
      subtitle: @subtitle()
      atLabel:  @def.at
      colLabel: if @def.col is 'FRT' && @result?.frt_time_basis is 'business' then 'FRT (jam kerja)' else @def.col
      rows:     rows
      total:    kpi.fmtNumber(total, 0)
      shown:    rows.length
      more:     total > rows.length
    )

  update: =>
    super
    # Ekspor/Pencarian hanya berguna kalau ada tiket
    empty = @state isnt 'ready' || !@result?.total
    @$('.js-submit, .js-kpi-drill-search').toggleClass('is-disabled', empty).attr('aria-disabled', empty)

  csvUrl: =>
    "#{@apiPath}/team_kpi/tickets?#{$.param(_.extend({}, @query, format: 'csv'))}"

  # Sesi login ikut terkirim; browser mengunduh CSV-nya.
  onSubmit: (e) =>
    e?.preventDefault()
    return if !@result?.total
    window.location.href = @csvUrl()

  onSearch: (e) =>
    e.preventDefault()
    numbers = _.pluck(@result?.tickets || [], 'number')
    return if !numbers.length
    @close()
    @navigate("#search/#{encodeURIComponent("number:(#{numbers.join(' OR ')})")}")

  onTicket: =>
    @close()

# "KPI Saya" (docs Section 24, artboard TeamKpi-Agent / TeamKpi-Agent-States):
# angka satu agent dengan rumus, format, dan tampilan yang sama dengan KPI Tim
# -- turunan App.DashboardTeamKpi, datanya dari endpoint yang sama dengan
# mine=1 (atau agent_id untuk "Lihat sebagai", hanya team_kpi.agents/admin).
# FRT = tiket yang PERTAMA dibalas agent; penyelesaian, SLA, dibuka ulang,
# CSAT, dan antrian = tiket milik agent (Section 21). Periode default =
# Setting team_kpi_default_window_days, sama dengan KPI Tim.
class App.DashboardKpiMine extends App.DashboardTeamKpi
  TABS: [
    { key: 'trend', label: 'Tren',           part: 'trend' }
    { key: 'topic', label: 'Per help topic', part: null }
  ]

  # Rasio Escalated hanya dari snapshot per grup -> tidak ada versi per agent
  METRICS: [
    { key: 'frt',        label: 'FRT median',   kind: 'duration', lowerBetter: true }
    { key: 'csat',       label: 'CSAT',         kind: 'score',    lowerBetter: false }
    { key: 'volume',     label: 'Tiket masuk',  kind: 'count',    lowerBetter: null }
    { key: 'resolution', label: 'Penyelesaian', kind: 'duration', lowerBetter: true }
  ]

  TAB_PREF: 'kpi_mine_tab'
  KPI_NAME: 'KPI Saya'
  OPTIONAL_PARTS: ['options', 'agentOptions']

  events: _.extend({}, App.DashboardTeamKpi::events,
    'change .js-kpi-viewas': 'onViewAs'
  )

  constructor: ->
    # sama dengan TeamKpiController#agents_access? ("Lihat sebagai")
    @canViewAs = @permissionCheck('team_kpi.agents') || @permissionCheck('admin')
    @viewAs = null
    super

  params: =>
    params = super
    if @viewAs then params.agent_id = @viewAs else params.mine = 1
    params

  load: (silent = false) =>
    parts = ['summary', 'options', 'queue']
    parts.push('agentOptions') if @canViewAs
    part = @tabPart()
    parts.push(part) if part
    @loadParts(parts, silent)

  partRequest: (part) =>
    switch part
      # daftar "Lihat sebagai" = agent di tab Per agent KPI Tim untuk periode ini
      when 'agentOptions' then { url: "#{@apiPath}/team_kpi/agent_options", data: { days: @days } }
      # 5 tiket lewat SLA paling lama (drill-down escalated yang sama dengan kartu tim)
      when 'queue'        then { url: "#{@apiPath}/team_kpi/tickets", data: _.extend(@params(), metric: 'escalated', limit: 5) }
      else super

  onViewAs: (e) =>
    id = parseInt($(e.currentTarget).val(), 10)
    @viewAs = if !id || id is App.Session.get('id') then null else id
    @load()

  viewAsName: =>
    return null if !@viewAs
    _.find(@data.agentOptions?.agents || [], (a) => a.id is @viewAs)?.name || "Agent ##{@viewAs}"

  # judul modal drill-down menyebut agent yang dilihat
  filterSummary: =>
    parts = super
    parts.unshift("Agent #{@viewAsName()}") if @viewAs
    parts

  # Kartu FRT, CSAT, Waktu penyelesaian, Reopening rate (sama dengan KPI Tim)
  # + dua kartu jumlah tanpa target sebagai konteks beban kerja.
  pickCards: (list, s, card, basis) =>
    cmp = s.comparison
    count = (o) =>
      card(_.extend({ basis: basis, unit: 'tiket', neutral: true, deltaKind: 'count', lowerBetter: null, footValue: '—' }, o))
    list.slice(0, 4).concat([
      count(
        title: 'Tiket dibalas pertama', value: @fmtNumber(s.frt_count, 0), current: s.frt_count, previous: cmp?.frt_count
        help: 'Tiket dari customer yang dibuat di periode terpilih dan respons pertamanya dari Anda. Konteks beban kerja, tanpa target.'
        drill: { metric: 'frt', label: 'Lihat tiket' }, drillCount: s.frt_count
      )
      count(
        title: 'Tiket masuk', value: @fmtNumber(s.ticket_created_count, 0), current: s.ticket_created_count, previous: cmp?.ticket_created_count
        help: 'Tiket milik Anda yang dibuat di periode terpilih. Konteks beban kerja, tanpa target.'
      )
    ])

  topicView: (s) =>
    view = super
    view.note += ' · FRT = tiket yang Anda balas pertama, SLA = tiket milik Anda saat closed'
    view

  extendView: (view, s, partFailed, partLoading) =>
    who = if @viewAs then @viewAsName() else 'Anda'
    view.mine = true
    view.basisNote = "FRT dari balasan pertama #{who} · penyelesaian, SLA, dibuka ulang, CSAT dari tiket milik #{who} saat closed"
    if @canViewAs
      me = App.Session.get('id')
      agents = @data.agentOptions?.agents || []
      agents = [{ id: me, name: 'Saya sendiri' }].concat(_.reject(agents, (a) -> a.id is me))
      view.viewAs = ({ id: a.id, name: a.name, selected: (a.id is (@viewAs || me)) } for a in agents)
    queue = @data.queue
    active = (s.ticket_new || 0) + (s.ticket_open || 0)
    view.mineQueue =
      who:       who
      title:     if @viewAs then "Antrian #{who}" else 'Antrian saya'
      active:    @fmtNumber(active, 0)
      activeLink: !@viewAs
      escalated: @fmtNumber(s.ticket_escalated, 0)
      escHot:    s.ticket_escalated > 0
      breach:    @fmtNumber(s.eskalasi_breached, 0)
      breachHot: s.eskalasi_breached > 0
      eskalasi:  @fmtNumber(s.eskalasi_active, 0)
      state:     if partFailed('queue') then 'failed' else if partLoading('queue') then 'loading' else if !s.ticket_escalated then (if active then 'none_late' else 'empty') else 'ready'
      rows: for t in queue?.tickets || []
        days = Math.round((Date.now() - new Date(t.at).getTime()) / 86400000)
        { id: t.id, number: t.number, title: t.title, topic: t.help_topic || '—', group: t.group || '—', created: @fmtDate(t.created_at), late: if days >= 1 then "Lewat #{days} hari" else 'Lewat < 1 hari' }
      more: if s.ticket_escalated > (queue?.tickets || []).length then "menampilkan #{(queue?.tickets || []).length} dari #{@fmtNumber(s.ticket_escalated, 0)}" else null
    frtLate = (s.frt_count || 0) - (s.frt_target_met_count || 0)
    slaItem = { tone: 'good', icon: 'check-circle', title: 'Lewat SLA saat closed: 0', drill: null }
    slaItem.sub = if s.sla_total then "Semua #{@fmtNumber(s.sla_total, 0)} tiket selesai sebelum batas SLA" else 'Belum ada tiket closed ber-SLA di periode ini'
    if s.sla_late
      slaItem = { tone: 'bad', icon: 'warning', title: "Lewat SLA saat closed: #{@fmtNumber(s.sla_late, 0)}", sub: 'Closed setelah batas SLA penyelesaian', drill: { metric: 'resolution', label: 'Lihat tiket (terlama dulu)' } }
    frtItem = { tone: 'bad', icon: 'clock', title: "Respons pertama lewat target: #{@fmtNumber(frtLate, 0)} tiket", sub: 'Dibalas setelah target help topic-nya', drill: null }
    frtItem.drill = { metric: 'frt', label: 'Lihat tiket (terlama dulu)' } if frtLate > 0
    reopenItem = { tone: 'ok', icon: 'clock-counter-clockwise', title: "Dibuka ulang: #{@fmtNumber(s.reopen_count || 0, 0)} tiket", sub: 'Customer membalas lagi setelah tiket closed', drill: null }
    reopenItem.drill = { metric: 'reopen', label: "Lihat #{@fmtNumber(s.reopen_count, 0)} tiket" } if s.reopen_count > 0
    view.learn = [frtItem, reopenItem, slaItem]
    view
