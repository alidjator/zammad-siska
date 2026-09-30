# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# .xlsx export of the "KPI Tim" dashboard (docs/DESIGN_TEAM_KPI_DASHBOARD.md
# Section 11) -- gap analysis item No. 7 ("download .xlsx"). Same scope,
# filters and comparison rule as the dashboard, one workbook with a sheet
# per section. The per-agent sheet is only included for users who may see
# /team_kpi/agents (report/admin), like the dashboard itself.
#
# Built directly on write_xlsx instead of ExcelSheet, which only writes a
# single table per file.
class Service::Dashboard::TeamKpi::Export
  CONTENT_TYPE = ExcelSheet::CONTENT_TYPE

  STATE_LABELS = {
    'supergood' => 'Sangat baik',
    'good'      => 'Baik',
    'ok'        => 'Cukup',
    'bad'       => 'Buruk',
    'superbad'  => 'Sangat buruk',
  }.freeze

  TREND_METRICS = [
    ['frt',        'FRT median (menit)'],
    ['csat',       'CSAT (1-5)'],
    ['volume',     'Tiket masuk'],
    ['resolution', 'Penyelesaian median (menit)'],
    ['escalated',  'Rasio Escalated (%)'],
  ].freeze

  BACKLOG_LABELS = {
    'lt_1d'   => '< 1 hari',
    'd1_3'    => '1-3 hari',
    'd3_7'    => '3-7 hari',
    'd7_30'   => '7-30 hari',
    'gte_30d' => '>= 30 hari',
  }.freeze

  WEEKDAYS = %w[Senin Selasa Rabu Kamis Jumat Sabtu Minggu].freeze

  def self.call(...)
    new(...).call
  end

  def initialize(window_days: nil, user: nil, filters: {}, compare: 'auto', include_agents: false)
    @args           = { window_days: window_days, user: user, filters: filters }
    @compare        = compare
    @include_agents = include_agents
  end

  # @return [Hash] { filename:, content: }
  def call
    require 'write_xlsx' # Only load this gem when it is really used.

    @summary  = Service::Dashboard::TeamKpi.call(**@args, compare: @compare)
    @tempfile = Tempfile.new(['kpi-tim', '.xlsx'])
    @workbook = WriteXLSX.new(@tempfile.path)
    build_formats

    sheet_summary
    sheet_trend
    sheet_sla
    sheet_frt_topic
    sheet_backlog
    sheet_heatmap
    sheet_agents if @include_agents

    @workbook.close
    { filename: filename, content: File.binread(@tempfile.path) }
  ensure
    @tempfile&.close!
  end

  private

  def timezone
    @timezone ||= Setting.get('timezone_default').presence || 'UTC'
  end

  def local(iso, format = '%Y-%m-%d %H:%M')
    Time.zone.parse(iso).in_time_zone(timezone).strftime(format)
  end

  def period_text(period)
    "#{local(period[:from])} s/d #{local(period[:to])} (#{timezone})"
  end

  def filename
    from = local(@summary[:period][:from], '%Y%m%d')
    to   = local(@summary[:period][:to], '%Y%m%d')
    "#{agent ? 'kpi_saya' : 'kpi_tim'}_#{from}_#{to}.xlsx"
  end

  # KPI Saya (Section 24): ekspor angka satu agent (filter agent_id dari controller)
  def agent
    return @agent if defined?(@agent)

    @agent = @summary[:filters][:agent_id] ? User.find_by(id: @summary[:filters][:agent_id]) : nil
  end

  def kpi_label
    agent ? 'KPI Saya' : 'KPI Tim'
  end

  def build_formats
    @f_title  = @workbook.add_format(bold: 1, size: 14)
    @f_label  = @workbook.add_format(bold: 1)
    @f_header = @workbook.add_format(bold: 1, bg_color: '#E7EAEE', border: 1, border_color: '#BEC8D0')
    @f_cell   = @workbook.add_format(border: 1, border_color: '#E7EAEE')
    @f_number = @workbook.add_format(border: 1, border_color: '#E7EAEE', num_format: '0.##')
    @f_note   = @workbook.add_format(italic: 1, color: '#5B6B79')
  end

  # Title + period/filter block shared by every sheet; returns next row.
  def sheet_head(sheet, title)
    sheet.write_string(0, 0, title, @f_title)
    rows = [
      ['Periode',    period_text(@summary[:period])],
      ['Pembanding', comparison_text],
      ['Filter',     filters_text],
      ['Dibuat',     local(@summary[:generated_at])],
    ]
    rows.each_with_index do |(label, value), i|
      sheet.write_string(2 + i, 0, label, @f_label)
      sheet.write_string(2 + i, 1, value)
    end
    2 + rows.size + 1
  end

  def comparison_text
    comparison = @summary[:comparison]
    return 'Tidak ada (rentang melewati batas histori, atau periode 2 tahun)' if !comparison

    mode = comparison[:mode] == 'yoy' ? 'tahun lalu, periode sama' : 'periode sebelumnya'
    "#{period_text(comparison)} -- #{mode}"
  end

  def filters_text
    f     = @summary[:filters]
    parts = []
    parts << "Grup: #{Group.where(id: f[:group_ids]).pluck(:name).join(', ')}" if f[:group_ids].present?
    parts << "Prioritas: #{Ticket::Priority.where(id: f[:priority_ids]).pluck(:name).join(', ')}" if f[:priority_ids].present?
    parts << "Channel: #{f[:channels].join(', ')}" if f[:channels].present?
    parts << "Kategori: #{f[:categories].join(', ')}" if f[:categories].present?
    parts.unshift("Agent: #{agent.fullname} (FRT = tiket yang ia balas pertama; lainnya = tiket miliknya)") if agent
    scope = "#{@summary[:group_ids_count] || 'semua'} grup yang bisa diakses"
    parts.empty? ? "Tanpa filter (#{scope})" : "#{parts.join(' | ')} (dalam #{scope})"
  end

  def write_table(sheet, row, header, records, widths: [])
    header.each_with_index { |h, col| sheet.write_string(row, col, h, @f_header) }
    widths.each_with_index { |w, col| sheet.set_column(col, col, w) if w }
    records.each_with_index do |record, i|
      record.each_with_index { |value, col| write_cell(sheet, row + 1 + i, col, value) }
    end
    row + 1 + records.size
  end

  def write_cell(sheet, row, col, value)
    case value
    when nil     then sheet.write_blank(row, col, @f_cell)
    when Numeric then sheet.write_number(row, col, value, @f_number)
    else              sheet.write_string(row, col, value.to_s, @f_cell)
    end
  end

  def state(value)
    STATE_LABELS[value]
  end

  def delta(current, previous)
    return nil if current.nil? || previous.nil?

    (current - previous).round(2)
  end

  def sheet_summary
    sheet = @workbook.add_worksheet('Ringkasan')
    row   = sheet_head(sheet, "#{kpi_label} -- Ringkasan")
    s     = @summary
    c     = s[:comparison] || {}
    rc    = s[:realtime_comparison] || {}
    r     = rc[:available] ? rc : {}

    records = [
      # FRT = median (rumus Reporting); status dari % sesuai target (Section 22.5)
      ['First Response Time (median)', s[:frt_median_minutes], 'menit', s[:frt_count], state(s[:frt_target_state]), c[:frt_median_minutes], delta(s[:frt_median_minutes], c[:frt_median_minutes]), 'Periode'],
      ['FRT sesuai target', s[:frt_target_met_percent], '%', s[:frt_count], nil, c[:frt_target_met_percent], delta(s[:frt_target_met_percent], c[:frt_target_met_percent]), 'Periode'],
      ['First Response Time (mean)', s[:frt_mean_minutes], 'menit', s[:frt_count], nil, c[:frt_mean_minutes], delta(s[:frt_mean_minutes], c[:frt_mean_minutes]), 'Periode'],
      ['CSAT', s[:csat_average], '1-5', s[:csat_count], state(s[:csat_state]), c[:csat_average], delta(s[:csat_average], c[:csat_average]), 'Periode'],
      # status = % closed dalam batas SLA (Section 22.6)
      ['Waktu penyelesaian (median)', s[:resolution_median_minutes], 'menit', s[:resolution_count], state(s[:sla_state]), c[:resolution_median_minutes], delta(s[:resolution_median_minutes], c[:resolution_median_minutes]), 'Periode'],
      ['Waktu penyelesaian (mean)', s[:resolution_mean_minutes], 'menit', s[:resolution_count], nil, c[:resolution_mean_minutes], delta(s[:resolution_mean_minutes], c[:resolution_mean_minutes]), 'Periode'],
      ['Reopening rate', s[:reopen_rate_percent], '%', s[:reopen_closed_count], state(s[:reopen_state]), c[:reopen_rate_percent], delta(s[:reopen_rate_percent], c[:reopen_rate_percent]), 'Periode'],
      ['SLA penyelesaian (tepat waktu)', s[:sla_within_percent], '%', s[:sla_total], nil, c[:sla_within_percent], delta(s[:sla_within_percent], c[:sla_within_percent]), 'Periode'],
      ['SLA terlambat', s[:sla_late], 'tiket', s[:sla_total], nil, c[:sla_late], delta(s[:sla_late], c[:sla_late]), 'Periode'],
      ['Median keterlambatan SLA', s[:sla_late_median_minutes], 'menit', s[:sla_late], nil, c[:sla_late_median_minutes], delta(s[:sla_late_median_minutes], c[:sla_late_median_minutes]), 'Periode'],
      ['Tiket New', s[:ticket_new], 'tiket', nil, nil, r[:ticket_new], delta(s[:ticket_new], r[:ticket_new]), 'Real-time'],
      ['Tiket Open', s[:ticket_open], 'tiket', nil, nil, r[:ticket_open], delta(s[:ticket_open], r[:ticket_open]), 'Real-time'],
      ['Tiket Escalated (lewat SLA)', s[:ticket_escalated], 'tiket', nil, nil, r[:ticket_escalated], delta(s[:ticket_escalated], r[:ticket_escalated]), 'Real-time'],
      ['Rasio Escalated', s[:escalation_rate_percent], '% dari New+Open', nil, state(s[:escalated_state]), r[:escalation_rate_percent], delta(s[:escalation_rate_percent], r[:escalation_rate_percent]), 'Real-time'],
      ['Eskalasi aktif', s[:eskalasi_active], 'tiket', nil, nil, r[:eskalasi_active], delta(s[:eskalasi_active], r[:eskalasi_active]), 'Real-time'],
      ['Breach eskalasi', s[:eskalasi_breached], 'tiket', nil, state(s[:eskalasi_breach_state]), r[:eskalasi_breached], delta(s[:eskalasi_breached], r[:eskalasi_breached]), 'Real-time'],
      ['Breach eskalasi (rate)', s[:eskalasi_breach_rate_percent], '% dari eskalasi aktif', nil, nil, r[:eskalasi_breach_rate_percent], delta(s[:eskalasi_breach_rate_percent], r[:eskalasi_breach_rate_percent]), 'Real-time'],
    ]
    row = write_table(sheet, row, ['Metrik', 'Nilai', 'Satuan', 'n', 'Status', 'Pembanding', 'Selisih', 'Dasar waktu'], records,
                      widths: [32, 12, 20, 10, 14, 12, 10, 12])
    realtime_note = if rc[:available]
                      "Pembanding baris Real-time = snapshot per jam #{local(rc[:captured_at])} (kemarin, jam sama)."
                    else
                      'Baris Real-time tanpa pembanding: snapshot kemarin belum ada atau filter prioritas/channel/kategori aktif.'
                    end
    sheet.write_string(row + 1, 0, 'n = ukuran sampel. Real-time = kondisi saat ekspor, tidak ikut filter periode.', @f_note)
    sheet.write_string(row + 2, 0, realtime_note, @f_note)
  end

  def sheet_trend
    sheet  = @workbook.add_worksheet('Tren')
    row    = sheet_head(sheet, "#{kpi_label} -- Tren")
    trends = TREND_METRICS.map { |metric, _| Service::Dashboard::TeamKpi::Trend.call(metric: metric, **@args, compare: @compare) }
    bucket = { 'day' => 'hari', 'week' => 'minggu', 'month' => 'bulan' }[trends.first[:bucket]]

    header = ["Awal #{bucket}"]
    TREND_METRICS.each do |metric, label|
      header << label
      header << "n #{label.split(' (').first}" if metric != 'volume' # volume value is the count itself
    end
    records = trends.first[:points].each_index.map { |i| trend_row(trends, :points, i) }
    row = write_table(sheet, row, header, records, widths: [14] + ([16] * (header.size - 1)))

    return if trends.first[:comparison].nil?

    row += 2
    sheet.write_string(row, 0, "Pembanding (#{comparison_text})", @f_label)
    cmp_records = trends.first[:comparison][:points].each_index.map { |i| trend_row(trends, :comparison, i) }
    write_table(sheet, row + 1, header, cmp_records)
  end

  # One bucket across all trend metrics; source = :points or :comparison.
  def trend_row(trends, source, index)
    points = ->(t) { source == :points ? t[:points] : t[:comparison][:points] }
    row = [points.call(trends.first)[index][:bucket_start]]
    trends.each_with_index do |t, i|
      point = points.call(t)[index]
      row << point[:value]
      row << point[:count] if TREND_METRICS[i][0] != 'volume'
    end
    row
  end

  # per help topic = dimensi SLA SISKA (Section 22.6)
  def sheet_sla
    sheet = @workbook.add_worksheet('SLA per help topic')
    row   = sheet_head(sheet, "#{kpi_label} -- SLA penyelesaian per help topic")
    records = @summary[:sla_by_help_topic].map { |r| [r[:help_topic] || '(tanpa help topic)', r[:target_minutes], r[:total], r[:within_sla], r[:late], r[:within_percent], r[:late_median_minutes]] }
    row = write_table(sheet, row, ['Help topic', 'Target SLA (menit kerja)', 'Tiket closed (ber-SLA)', 'Tepat waktu', 'Terlambat', '% tepat waktu', 'Median terlambat (menit)'], records, widths: [34, 20, 20, 12, 12, 14, 22])
    sheet.write_string(row + 1, 0, 'Tiket closed di periode yang punya batas penyelesaian SLA (close_escalation_at, dihitung Zammad dengan kalender SLA).', @f_note)
  end

  # FRT per help topic (Section 23), angka sama dengan sub-tab "Per help topic".
  def sheet_frt_topic
    sheet = @workbook.add_worksheet('FRT per help topic')
    row   = sheet_head(sheet, "#{kpi_label} -- First Response Time per help topic")
    records = @summary[:frt_by_help_topic].map do |r|
      [r[:help_topic] || '(tanpa help topic)', r[:target_minutes], r[:own_target] ? 'sendiri' : 'global', r[:count], r[:median_minutes],
       r[:target_met_count], r[:target_met_percent], delta(r[:target_met_percent], r[:prev_target_met_percent])]
    end
    header = ['Help topic', 'Target FRT (menit)', 'Asal target', 'Tiket (n)', 'FRT median (menit)', 'Sesuai target', '% sesuai target', 'Selisih vs pembanding (poin)']
    row = write_table(sheet, row, header, records, widths: [34, 16, 12, 10, 16, 14, 14, 24])
    sheet.write_string(row + 1, 0, 'Populasi, menit, dan target sama dengan kartu First Response Time. Target kosong = campuran (mis. live chat memakai target chat).', @f_note)
  end

  def sheet_backlog
    sheet = @workbook.add_worksheet('Backlog')
    row   = sheet_head(sheet, "#{kpi_label} -- Umur backlog (real-time)")
    records = @summary[:backlog_aging].map { |b| [BACKLOG_LABELS[b[:bucket]] || b[:bucket], b[:count]] }
    write_table(sheet, row, ['Umur tiket belum closed', 'Jumlah'], records, widths: [26, 10])
  end

  def sheet_heatmap
    sheet   = @workbook.add_worksheet('Heatmap')
    row     = sheet_head(sheet, "#{kpi_label} -- Rata-rata tiket masuk per jam")
    heatmap = Service::Dashboard::TeamKpi::Heatmap.call(**@args)
    cells   = heatmap[:cells].index_by { |c| [c[:dow], c[:hour]] }
    header  = ['Hari'] + (0..23).map { |h| format('%02d', h) }
    records = (1..7).map { |dow| [WEEKDAYS[dow - 1]] + (0..23).map { |h| cells[[dow, h]][:avg_per_day] } }
    row = write_table(sheet, row, header, records, widths: [10] + ([6] * 24))
    sheet.write_string(row + 1, 0, "Rata-rata per kemunculan hari tersebut di periode (#{heatmap[:timezone]}).", @f_note)
  end

  def sheet_agents
    sheet  = @workbook.add_worksheet('Agent')
    row    = sheet_head(sheet, "#{kpi_label} -- Performa per agent")
    agents = Service::Dashboard::TeamKpi::Agents.call(**@args, limit: 200)
    records = agents[:agents].map do |a|
      [a[:unassigned] ? 'Belum ditugaskan' : a[:name], a[:tickets], a[:frt_target_met_percent], a[:frt_median_minutes], a[:frt_mean_minutes], a[:frt_count],
       a[:csat_average], a[:csat_count], a[:escalated], a[:eskalasi_breached]]
    end
    # FRT milik pembalas pertama (Section 21)
    header = ['Agent', 'Tiket (dibuat di periode)', 'FRT sesuai target (%)', 'FRT median (menit)', 'FRT mean (menit)', 'n FRT (pembalas pertama)', 'CSAT', 'n CSAT', 'Escalated (real-time)', 'Breach eskalasi (real-time)']
    write_table(sheet, row, header, records, widths: [28, 12, 14, 12, 12, 12, 8, 8, 12, 14])
  end
end
