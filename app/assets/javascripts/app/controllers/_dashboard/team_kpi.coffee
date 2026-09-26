# "KPI Tim" Dashboard tab -- redesign BI (mockup B di kanvas desain "SISKA
# Widget - Kit Tailwind Compliance", artboard TeamKpi-KitB), gaya kit Able
# Pro seperti panel agent (siska_agent_chat.scss). Data dari endpoint Fase
# 2/3 (docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 10-12):
#   /team_kpi (kartu, antrian, SLA, backlog, pembanding, ambang),
#   /team_kpi/trend, /team_kpi/heatmap, /team_kpi/agents (hanya report/admin),
#   /team_kpi/export (unduhan .xlsx dengan filter yang sama).
#
# Semua hitungan tampilan (skala state, delta, titik grafik, level heatmap)
# dilakukan di sini; team_kpi.jst.eco hanya menampilkan.
class App.DashboardTeamKpi extends App.Controller
  events:
    'click .js-kpi-period':  'onPeriod'
    'change .js-kpi-group':  'onGroup'
    'click .js-kpi-metric':  'onMetric'
    'click .js-kpi-export':  'onExport'
    'click .js-kpi-retry':   'onRetry'

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
    @metric  = 'frt'
    @canSeeAgents = @permissionCheck('report') || @permissionCheck('admin')
    @data = {}
    @load()
    @startAutoRefresh()

  onPeriod: (e) =>
    e.preventDefault()
    @days = parseInt($(e.currentTarget).data('days'), 10)
    @load()

  onGroup: (e) =>
    @groupId = $(e.currentTarget).val()
    @load()

  onMetric: (e) =>
    e.preventDefault()
    @metric = $(e.currentTarget).data('metric')
    @loadParts(['trend'])

  onRetry: (e) =>
    e.preventDefault()
    @load()

  # Sesi login agent (cookie) ikut terkirim, jadi cukup navigasi ke URL
  # ekspor dengan filter yang sama; browser mengunduh .xlsx-nya.
  onExport: (e) =>
    e.preventDefault()
    window.location.href = "#{@apiPath}/team_kpi/export?#{$.param(@params())}"

  params: =>
    params = { days: @days }
    params.group_ids = @groupId if @groupId
    params

  load: (silent = false) =>
    parts = ['summary', 'trend', 'heatmap']
    parts.push('agents') if @canSeeAgents
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
    urls =
      summary: "#{@apiPath}/team_kpi"
      trend:   "#{@apiPath}/team_kpi/trend"
      heatmap: "#{@apiPath}/team_kpi/heatmap"
      agents:  "#{@apiPath}/team_kpi/agents"
    done = =>
      pending -= 1
      return if pending > 0
      @loading = false
      @failed  = failed
      @render()

    for part in parts
      do (part) =>
        data = @params()
        data.metric = @metric if part is 'trend'
        data.limit  = 50 if part is 'agents'
        @ajax(
          id:          "team_kpi_#{part}"
          type:        'GET'
          url:         urls[part]
          data:        data
          processData: true
          success: (response) =>
            @data[part] = response
            @fetchedAt  = new Date() if part is 'summary'
            done()
          error: =>
            failed.push(part)
            done()
        )

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
      else             ["< #{t.good_min}%", "≥ #{t.good_min}%", "≥ #{t.ok_min}%", "≥ #{t.bad_min}%", "≥ #{t.superbad_min}%"]
    segs = for s, i in @STATES
      { state: s, active: s is state, tip: "#{@STATE_LABELS[s]}: #{tips[i]}" }
    { segs: segs, first: "#{@STATE_LABELS.supergood} #{tips[0]}" }

  # Selisih terhadap pembanding, diwarnai membaik/memburuk sesuai arah metrik.
  delta: (current, previous, kind, lowerBetter) =>
    return null if !current? || !previous?
    diff = current - previous
    return { text: 'sama', cls: 'is-flat' } if Math.abs(diff) < 0.005
    arrow = if diff > 0 then '▲' else '▼'
    text = switch kind
      when 'duration' then @fmtDurationText(Math.abs(diff))
      when 'rate'     then "#{@fmtNumber(Math.abs(diff), 1)} poin"
      when 'count'    then @fmtNumber(Math.abs(diff), 0)
      else                 @fmtNumber(Math.abs(diff), 2)
    return { text: "#{arrow} #{text}", cls: 'is-flat' } if !lowerBetter?
    better = if lowerBetter then diff < 0 else diff > 0
    { text: "#{arrow} #{text}", cls: if better then 'is-better' else 'is-worse' }

  cards: (s) =>
    t   = s.thresholds || {}
    cmp = s.comparison
    cmpLabel = if cmp?.mode is 'yoy' then 'tahun lalu, periode sama' else 'periode sebelumnya'
    basis = @periodLabel()
    frt = @fmtDuration(s.frt_median_minutes)
    res = @fmtDuration(s.resolution_median_minutes)
    outlier = s.frt_median_minutes? && s.frt_mean_minutes? && s.frt_mean_minutes > s.frt_median_minutes * 3

    card = (o) =>
      o.stateKey   = o.state || 'none'
      o.stateLabel = if o.state then @STATE_LABELS[o.state] else (if o.neutral then null else 'Tidak ada data')
      o.scale      = if o.state && o.scaleKind then @scale(o.state, o.scaleKind, t[o.scaleKey]) else null
      o.empty      = o.value is '—'
      o.small      = !o.live && o.n? && o.n > 0 && o.n < @SMALL_SAMPLE
      if o.live
        o.deltaNote = 'Real-time · tanpa pembanding'
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

    [
      card(
        title: 'First Response Time', basis: basis
        help: 'Median waktu dari tiket dibuat sampai respons pertama agent -- hanya tiket yang dibuka customer, dibuat di periode terpilih. Mean ditampilkan sebagai pembanding: jauh di atas median berarti ada outlier.'
        value: frt.value, unit: frt.unit, state: s.frt_state, n: s.frt_count, nLabel: 'tiket'
        emptyNote: 'Belum ada tiket customer yang direspons di periode ini'
        scaleKind: 'frt', scaleKey: 'frt'
        current: s.frt_median_minutes, previous: cmp?.frt_median_minutes, deltaKind: 'duration', lowerBetter: true
        footLabel: 'Rata-rata (mean)', footValue: @fmtDurationText(s.frt_mean_minutes), outlier: outlier
      )
      card(
        title: 'CSAT', basis: basis
        help: 'Rata-rata skor kepuasan pelanggan (1–5) dari rating yang masuk di periode terpilih.'
        value: @fmtNumber(s.csat_average, 2), unit: (if s.csat_average? then '/ 5' else ''), state: s.csat_state, n: s.csat_count, nLabel: 'rating'
        emptyNote: 'Belum ada rating di periode ini'
        scaleKind: 'csat', scaleKey: 'csat'
        current: s.csat_average, previous: cmp?.csat_average, deltaKind: 'score', lowerBetter: false
        footLabel: 'Rating masuk', footValue: @fmtNumber(s.csat_count, 0)
      )
      card(
        title: 'Waktu penyelesaian', basis: basis, neutral: true
        help: 'Median waktu dari tiket dibuat sampai pertama kali closed, untuk tiket yang closed di periode terpilih.'
        value: res.value, unit: res.unit, state: null, n: s.resolution_count, nLabel: 'closed'
        emptyNote: 'Belum ada tiket closed di periode ini'
        current: s.resolution_median_minutes, previous: cmp?.resolution_median_minutes, deltaKind: 'duration', lowerBetter: true
        footLabel: 'Rata-rata (mean)', footValue: @fmtDurationText(s.resolution_mean_minutes)
      )
      card(
        title: 'Reopening rate', basis: basis
        help: 'Persentase tiket yang dibuka ulang setelah closed, dari tiket yang closed di periode terpilih. Ambangnya sama dengan widget My Stats.'
        value: @fmtNumber(s.reopen_rate_percent, 1), unit: (if s.reopen_rate_percent? then '%' else ''), state: s.reopen_state, n: s.reopen_closed_count, nLabel: 'closed'
        emptyNote: 'Belum ada tiket closed di periode ini'
        scaleKind: 'rate', scaleKey: 'reopen'
        current: s.reopen_rate_percent, previous: cmp?.reopen_rate_percent, deltaKind: 'rate', lowerBetter: true
        footLabel: 'Dibuka ulang', footValue: "#{@fmtNumber(s.reopen_count, 0)} tiket"
      )
      card(
        title: 'Rasio Escalated', basis: 'Real-time', live: true
        help: 'Tiket belum closed yang batas SLA-nya (escalation_at) sudah lewat, dibagi jumlah tiket New + Open. Real-time, tidak ikut filter periode.'
        value: @fmtNumber(s.escalation_rate_percent, 1), unit: '%', state: s.escalated_state
        scaleKind: 'rate', scaleKey: 'escalated'
        footLabel: 'Lewat SLA', footValue: "#{@fmtNumber(s.ticket_escalated, 0)} dari #{@fmtNumber((s.ticket_new || 0) + (s.ticket_open || 0), 0)}"
      )
      card(
        title: 'Breach eskalasi', basis: 'Real-time', live: true
        help: 'Tiket berstatus Eskalasi yang melewati batas waktu eskalasi (escalation_deadline_at). Status dihitung dari persentasenya terhadap tiket Eskalasi aktif. Real-time.'
        value: @fmtNumber(s.eskalasi_breached, 0), unit: 'tiket', state: s.eskalasi_breach_state
        scaleKind: 'rate', scaleKey: 'eskalasi_breach'
        footLabel: 'Eskalasi aktif', footValue: "#{@fmtNumber(s.eskalasi_active, 0)} (#{@fmtNumber(s.eskalasi_breach_rate_percent, 1)}% breach)"
      )
    ]

  # ------------------------------------------------------------- grafik

  trendView: (trend) =>
    metric = _.find(@METRICS, (m) => m.key is @metric)
    tabs = for m in @METRICS
      { key: m.key, label: m.label, active: m.key is @metric }
    view = { tabs: tabs, metricLabel: metric.label, empty: true, emptyText: 'Memuat…' }
    return view if !trend || !trend.points

    cur  = _.map(trend.points, (p) -> p.value)
    prev = if trend.comparison then _.map(trend.comparison.points, (p) -> p.value) else []
    values = _.filter(cur.concat(prev), (v) -> v?)
    if !_.some(cur, (v) -> v?) || (metric.kind is 'count' && !_.some(cur, (v) -> v > 0))
      view.emptyText = 'Belum ada data untuk periode dan filter ini.'
      return view

    lo  = Math.min.apply(null, values)
    hi  = Math.max.apply(null, values)
    pad = (hi - lo) * 0.15 || Math.max(hi * 0.15, 1)
    lo  = Math.max(0, lo - pad)
    hi  = hi + pad
    n   = cur.length
    x = (i) -> if n <= 1 then '500' else (i / (n - 1) * 1000).toFixed(1)
    y = (v) -> (210 - (v - lo) / (hi - lo) * 200).toFixed(1)
    # Garis putus di bucket tanpa data (value null), bukan ditarik ke 0.
    segments = (series) ->
      out = []
      current = []
      for v, i in series
        if v?
          current.push("#{x(i)},#{y(v)}")
        else if current.length
          out.push(current.join(' '))
          current = []
      out.push(current.join(' ')) if current.length
      out

    fmt = (v) =>
      return '—' if !v?
      switch metric.kind
        when 'duration' then @fmtDurationText(v)
        when 'score'    then @fmtNumber(v, 2)
        else                 @fmtNumber(v, 0)
    avg = (series) ->
      xs = _.filter(series, (v) -> v?)
      return null if !xs.length
      _.reduce(xs, ((a, b) -> a + b), 0) / xs.length
    curAvg  = avg(cur)
    prevAvg = if trend.comparison then avg(prev) else null
    d = @delta(curAvg, prevAvg, metric.kind, metric.lowerBetter)

    yLabels = for i in [0..4]
      fmt(hi - (hi - lo) * i / 4)
    nx = if n <= 8 then n else 6
    xLabels = for j in [0...nx]
      idx   = Math.round(j * (n - 1) / Math.max(nx - 1, 1))
      start = trend.points[idx].bucket_start
      if trend.bucket is 'month'
        date = new Date("#{start}T00:00:00")
        "#{@MONTHS[date.getMonth()]} #{String(date.getFullYear()).substr(2)}"
      else
        @fmtDate(start)
    bucketName = { day: 'hari', week: 'minggu', month: 'bulan' }[trend.bucket]
    subtitle = "#{metric.label} per #{bucketName} · #{@fmtRange(trend.period)}"
    subtitle += " vs #{@fmtRange(trend.comparison.period)}" if trend.comparison

    _.extend(view,
      empty:     false
      subtitle:  subtitle
      curLines:  segments(cur)
      prevLines: segments(prev)
      hasCmp:    !!trend.comparison
      cmpLabel:  if trend.comparison?.mode is 'yoy' then 'Tahun lalu' else 'Periode sebelumnya'
      curAvg:    fmt(curAvg)
      prevAvg:   fmt(prevAvg)
      delta:     d
      yLabels:   yLabels
      xLabels:   xLabels
    )

  heatmapView: (heatmap) =>
    return null if !heatmap || !heatmap.cells
    max = heatmap.max_avg || 0
    byKey = {}
    byKey["#{c.dow}-#{c.hour}"] = c for c in heatmap.cells
    rows = for dow in [1..7]
      cells = for hour in [0..23]
        c = byKey["#{dow}-#{hour}"] || { avg_per_day: 0, total: 0 }
        level = if max <= 0 || c.avg_per_day <= 0 then 0 else Math.min(4, Math.ceil(c.avg_per_day / max * 4))
        { level: level, tip: "#{@WEEKDAYS[dow - 1]} #{@pad2(hour)}.00–#{@pad2(hour)}.59 · rata-rata #{@fmtNumber(c.avg_per_day, 1)} tiket masuk/hari (total #{c.total})" }
      { day: @WEEKDAYS[dow - 1].substr(0, 3), cells: cells }
    hours = for h in [0..23]
      if h % 3 is 0 then @pad2(h) else ''
    { rows: rows, hours: hours, max: @fmtNumber(max, 1), hasData: max > 0 }

  slaView: (s) =>
    for row in (s.sla_by_priority || [])
      pct = row.within_percent
      cls = if !pct? then 'none' else if pct >= 90 then 'good' else if pct >= 75 then 'ok' else 'bad'
      { priority: row.priority, pct: (if pct? then pct else 0), pctText: (if pct? then "#{@fmtNumber(pct, 1)}%" else '—'), total: @fmtNumber(row.total, 0), cls: cls }

  backlogView: (s) =>
    rows = s.backlog_aging || []
    max  = _.max(_.map(rows, (r) -> r.count).concat([1]))
    for row, i in rows
      { label: @BACKLOG_LABELS[row.bucket] || row.bucket, count: @fmtNumber(row.count, 0), pct: Math.round(row.count / max * 100), old: i >= 3 }

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
        frt: @fmtDurationText(a.frt_median_minutes), frtTip: "Mean #{@fmtDurationText(a.frt_mean_minutes)} · n #{a.frt_count} tiket"
        csat: @fmtNumber(a.csat_average, 2), csatTip: "n #{a.csat_count} rating", csatCls: csatCls
        escalated: @fmtNumber(a.escalated, 0), breach: @fmtNumber(a.eskalasi_breached, 0), breachHot: a.eskalasi_breached > 0
      }

  groupOptions: =>
    ids = _.map(App.User.current()?.allGroupIds('read') || [], (id) -> parseInt(id, 10))
    groups = _.filter(App.Group.all(), (g) -> g.active && _.contains(ids, g.id))
    _.sortBy(_.map(groups, (g) => { id: g.id, name: g.name, selected: "#{g.id}" is "#{@groupId}" }), 'name')

  # ------------------------------------------------------------- render

  render: =>
    s = @data.summary
    failed = @failed || []
    periods = for p in @PERIODS
      { days: p.days, label: p.label, active: p.days is @days }

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

    if s
      total = (s.ticket_new || 0) + (s.ticket_open || 0)
      _.extend(view,
        cmpRange:  if s.comparison then "#{@fmtRange(s.comparison)}#{if s.comparison.mode is 'yoy' then ' (tahun lalu)' else ''}" else null
        noCmpNote: if @days >= 730 then 'Tanpa pembanding untuk 2 tahun' else 'Tanpa pembanding'
        basis:     @periodLabel()
        cards:     @cards(s)
        queue:
          total:     @fmtNumber(total, 0)
          new:       @fmtNumber(s.ticket_new, 0)
          open:      @fmtNumber(s.ticket_open, 0)
          escalated: @fmtNumber(s.ticket_escalated, 0)
          newPct:    @fmtNumber((s.ticket_new || 0) / Math.max(total, 1) * 100, 1)
          openPct:   @fmtNumber((s.ticket_open || 0) / Math.max(total, 1) * 100, 1)
        trend:     @trendView(@data.trend)
        heatmap:   @heatmapView(@data.heatmap)
        sla:       @slaView(s)
        backlog:   @backlogView(s)
        agents:    @agentsView(@data.agents)
      )

    @html App.view('dashboard/team_kpi')(view)
    @$('.js-kpi-tip').tooltip(container: 'body')
