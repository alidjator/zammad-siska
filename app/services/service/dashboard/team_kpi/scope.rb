# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared ticket scope for every "KPI Tim" endpoint (summary, trend,
# heatmap, agents) -- see docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 10.
#
# Two jobs:
#   1. Access: tickets are limited to the groups the requesting user can
#      read (User#group_ids_access('read')). Before this, the KPI tab
#      counted every ticket in the system for every agent.
#   2. Filters: optional group_ids / priority_ids / channels
#      (create_article_type names) / categories, narrowing that scope
#      further. A filter can never widen access -- group_ids is
#      intersected with the readable groups.
#
# Period ranges are half-open [from, to). Comparison ranges follow the
# dashboard's rule (compare: 'auto'): windows under a year compare with
# the equally long period right before, 1 year compares with the same
# period last year, and 2 years (max window) has no comparison.
#
# Production keeps only ~2 years of tickets (= team_kpi_max_window_days),
# so any comparison range that starts before that history horizon is
# dropped (nil), whatever the mode -- otherwise it would be computed on a
# partly missing period and look like a real drop. Staging holds data
# back to 2020 and would not show the problem. One day of tolerance
# keeps "1 year vs last year" available across a leap day.
class Service::Dashboard::TeamKpi::Scope
  COMPARE_MODES = %w[auto previous yoy none].freeze

  attr_reader :user, :filters

  def initialize(user: nil, filters: {})
    @user    = user
    @filters = normalize_filters(filters)
  end

  # Group ids the scope is limited to, or nil for "no restriction" (only
  # when no user is given, e.g. internal callers / the console).
  def group_ids
    return @group_ids if defined?(@group_ids)

    readable = user ? user.group_ids_access('read') : nil
    wanted   = filters[:group_ids].presence

    @group_ids = if readable && wanted
                   readable & wanted
                 else
                   readable || wanted
                 end
  end

  # All tickets the requesting user may see, with filters applied.
  def tickets
    relation = Ticket.all
    relation = relation.where(group_id: group_ids) if !group_ids.nil?
    relation = relation.where(priority_id: filters[:priority_ids]) if filters[:priority_ids].present?
    relation = relation.where(create_article_type_id: channel_type_ids) if filters[:channels].present?
    relation = relation.where(category: filters[:categories]) if filters[:categories].present?
    relation
  end

  # First Response Time population, shared by summary, trend and agents:
  # tickets created in the range that a *customer* opened and that got a
  # first response. Agent-created tickets (outbound email, phone calls
  # logged by the agent) get first_response_at = created_at, i.e. 0 min --
  # ~60% of all tickets here, which pulled the median to 0.0 while
  # customer-initiated tickets wait ~75 min. first_response_at < start
  # is excluded as in Report::TicketFirstResponseTime (known ~7h timezone
  # bug, docs/BUG_REPORT_TIMEZONE_FIRST_RESPONSE.md).
  #
  # Live chat tickets are customer-initiated too, but Chat::Session opens
  # them with a System article ("Live chat dimulai.") only when an agent
  # accepts the chat -- so they are included via their chat session, and
  # the wait starts when the customer started the chat (FRT_START_SQL),
  # queue time included (docs Section 16).
  FRT_CHAT_JOIN = <<~SQL.squish.freeze
    LEFT JOIN (
      SELECT ticket_id, MIN(created_at) AS started_at
      FROM chat_sessions WHERE ticket_id IS NOT NULL GROUP BY ticket_id
    ) frt_chat ON frt_chat.ticket_id = tickets.id
  SQL
  FRT_START_SQL   = 'LEAST(COALESCE(frt_chat.started_at, tickets.created_at), tickets.created_at)'.freeze
  FRT_MINUTES_SQL = "EXTRACT(EPOCH FROM (tickets.first_response_at - #{FRT_START_SQL})) / 60".freeze

  # Dasar waktu FRT (Section 22, Setting team_kpi_frt_time_basis, default
  # jam kerja): menit JAM KERJA = tickets.first_response_in_min, dihitung
  # Zammad dengan kalender SLA tiket (sekarang "Indonesia/Jakarta", Sen-Jum
  # 08-17 + libur) -- grup 24/7 nanti cukup diberi SLA berkalender 24/7.
  # Dua pengecualian tetap jam kalender: live chat (menunggu sejak chat
  # dimulai, first_response_in_min dihitung dari tiket dibuat) dan tiket
  # tanpa first_response_in_min (tidak cocok SLA mana pun, ~3%).
  FRT_BUSINESS_MINUTES_SQL = <<~SQL.squish.freeze
    CASE WHEN frt_chat.ticket_id IS NOT NULL OR tickets.first_response_in_min IS NULL
      THEN #{FRT_MINUTES_SQL} ELSE tickets.first_response_in_min END
  SQL

  def self.frt_time_basis
    Setting.get('team_kpi_frt_time_basis') == 'calendar' ? 'calendar' : 'business'
  end

  # Rumus menit FRT yang berlaku (kartu, tren, per agent, drill-down).
  # Selalu dipakai bersama frt_tickets (butuh join frt_chat).
  def self.frt_minutes_sql
    frt_time_basis == 'business' ? FRT_BUSINESS_MINUTES_SQL : FRT_MINUTES_SQL
  end

  # Atribusi FRT (Section 21, keputusan user): FRT milik agent yang
  # PERTAMA membalas -- penulis artikel Agent publik pertama tiket itu --
  # bukan pemilik tiket. Metrik penanganan (penyelesaian, SLA, reopen, CSAT)
  # tetap milik pemilik terakhir; antrian real-time milik pemilik sekarang.
  # Di live chat artikel Agent pertama = balasan agent yang menerima chat,
  # walau owner dikosongkan lagi saat agent terputus (Section 16).
  # Dipakai dengan frt_tickets; kolom: frt_resp.responder_id.
  FRT_RESPONDER_JOIN = <<~SQL.squish.freeze
    LEFT JOIN LATERAL (
      SELECT a.created_by_id AS responder_id
      FROM ticket_articles a
      JOIN ticket_article_senders frt_s ON frt_s.id = a.sender_id AND frt_s.name = 'Agent'
      WHERE a.ticket_id = tickets.id AND a.internal = false
      ORDER BY a.created_at, a.id
      LIMIT 1
    ) frt_resp ON true
  SQL

  # Target FRT per tiket (Section 20): dari grupnya (Group#frt_target_minutes,
  # default) atau dari kanal pembuat tiketnya (Setting
  # team_kpi_frt_target_by_channel), sesuai Setting team_kpi_frt_target_basis.
  # Isian kosong = target global = good_max di team_kpi_frt_thresholds.
  # Dipakai bersama FRT_TARGET_JOIN di atas frt_tickets.
  FRT_TARGET_CHANNELS = {
    'email'    => 'email',
    'web'      => 'web',
    'phone'    => 'phone',
    'chat'     => 'chat',
    'sms'      => 'sms',
    'telegram' => 'telegram personal-message',
    'whatsapp' => 'whatsapp message',
  }.freeze
  FRT_TARGET_JOIN = <<~SQL.squish.freeze
    JOIN groups frt_g ON frt_g.id = tickets.group_id
    LEFT JOIN ticket_article_types frt_at ON frt_at.id = tickets.create_article_type_id
  SQL

  def self.frt_target_basis
    Setting.get('team_kpi_frt_target_basis') == 'channel' ? 'channel' : 'group'
  end

  def self.frt_target_global_minutes
    (Setting.get('team_kpi_frt_thresholds') || {})['good_max'].to_f
  end

  # SQL expression: target (menit) untuk baris tiket saat ini.
  def self.frt_target_sql
    global = frt_target_global_minutes
    if frt_target_basis == 'channel'
      map   = Setting.get('team_kpi_frt_target_by_channel') || {}
      whens = FRT_TARGET_CHANNELS.filter_map do |key, type_name|
        minutes = map[key].to_f
        next if minutes <= 0

        "WHEN #{ActiveRecord::Base.connection.quote(type_name)} THEN #{minutes}"
      end
      return global.to_s if whens.empty?

      "COALESCE(CASE frt_at.name #{whens.join(' ')} END, #{global})"
    elsif Group.column_names.include?('frt_target_minutes')
      "COALESCE(NULLIF(frt_g.frt_target_minutes, 0), #{global})"
    else
      global.to_s
    end
  end

  def frt_tickets(range)
    tickets
      .joins(FRT_CHAT_JOIN)
      .where(created_at: range)
      .where('tickets.create_article_sender_id = :customer OR (tickets.create_article_type_id = :chat AND frt_chat.ticket_id IS NOT NULL)',
             customer: customer_sender_id, chat: chat_type_id)
      .where.not(first_response_at: nil)
      .where("tickets.first_response_at >= #{FRT_START_SQL}")
  end

  def self.window_range(days, now: Time.zone.now)
    (now - days.days)...now
  end

  HORIZON_TOLERANCE = 1.day

  # @return [Hash, nil] { mode:, range: } or nil when there is no comparison
  def self.comparison(range, days, mode: 'auto')
    result = comparison_range(range, days, mode)
    return nil if result.nil?
    return nil if result[:range].begin < history_start(range.end)

    result
  end

  # Oldest point the comparison may reach back to.
  def self.history_start(now)
    now - Service::Dashboard::TeamKpi.max_window_days.days - HORIZON_TOLERANCE
  end

  def self.comparison_range(range, days, mode)
    mode = COMPARE_MODES.include?(mode.to_s) ? mode.to_s : 'auto'
    if mode == 'auto'
      mode = if days >= Service::Dashboard::TeamKpi.max_window_days
               'none'
             elsif days >= 365
               'yoy'
             else
               'previous'
             end
    end

    case mode
    when 'none'
      nil
    when 'yoy'
      { mode: 'yoy', range: (range.begin - 1.year)...(range.end - 1.year) }
    else
      length = range.end - range.begin
      { mode: 'previous', range: (range.begin - length)...range.begin }
    end
  end

  private

  def customer_sender_id
    @customer_sender_id ||= Ticket::Article::Sender.find_by!(name: 'Customer').id
  end

  def chat_type_id
    @chat_type_id ||= Ticket::Article::Type.find_by!(name: 'chat').id
  end

  def channel_type_ids
    Ticket::Article::Type.where(name: filters[:channels]).pluck(:id)
  end

  def normalize_filters(raw)
    raw = (raw || {}).to_h.symbolize_keys
    {
      group_ids:    int_list(raw[:group_ids]),
      priority_ids: int_list(raw[:priority_ids]),
      channels:     str_list(raw[:channels]),
      categories:   str_list(raw[:categories]),
    }
  end

  def int_list(value)
    Array(value).flat_map { |v| v.to_s.split(',') }.map(&:strip).compact_blank.map(&:to_i).select(&:positive?).uniq
  end

  def str_list(value)
    Array(value).flat_map { |v| v.to_s.split(',') }.map(&:strip).compact_blank.uniq
  end
end
