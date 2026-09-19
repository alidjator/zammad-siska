# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::ChatSessionInit < Sessions::Event::ChatBase

=begin

a customer requests a new chat session

payload (widget anonim, Fase 5)

  {
    event: 'chat_session_init',
    data: {
      chat_id: 'the id of chat',
      url: 'the browser url',
      name: 'the customer name (Fase 5 -- wajib, lihat DESIGN_LIVE_CHAT_ENHANCEMENT.md 5.1.1)',
      email: 'the customer email (Fase 5 -- wajib)',
    },
  }

payload (user login, follow-up tiket, Fase 6 -- lihat
docs/DESIGN_CHAT_SELF_SERVICE.md Section 5.2)

  {
    event: 'chat_session_init',
    data: {
      ticket_id: 'id tiket MILIK user yang login, masih terbuka',
      url: 'the browser url',
    },
  }

  -- chat_id/name/email TIDAK dipakai untuk jalur ini: chat_id
  dihitung server (Section 5.6), name/email diambil dari akun yang
  login (Section 5.1), bukan dari payload.

return is sent as message back to peer

=end

  # Fase 5 -- Item No. 5 (Live Chat Enhancement, Auto-Create Ticket).
  # See docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.1.1/5.1.2. Nama
  # & email sekarang WAJIB diisi lewat form pra-chat di widget SEBELUM
  # `chat_session_init` dikirim -- validasi di sini adalah pertahanan
  # LAPIS KEDUA (server-side), bukan sekadar percaya validasi client,
  # karena WebSocket bisa saja dipanggil langsung tanpa lewat widget
  # resminya.
  EMAIL_FORMAT = %r{\A[^@\s]+@[^@\s]+\.[^@\s]+\z}.freeze

  def run
    return super if super

    # Fase 6 -- @session cuma terisi kalau pemanggil user Zammad yang
    # SUDAH LOGIN (beda dari widget publik anonim, yang @session-nya
    # selalu kosong). Jalur ini SAMA SEKALI TERPISAH dari jalur widget
    # di bawah -- lihat docs/DESIGN_CHAT_SELF_SERVICE.md Section 5.2.
    return self_service_init if @session && @session['id']

    return if !check_chat_exists

    name  = @payload['data']['name'].to_s.strip
    email = @payload['data']['email'].to_s.strip.downcase

    if name.blank? || email.blank? || !email.match?(EMAIL_FORMAT)
      return {
        event: 'chat_session_init',
        data:  {
          state:   'failed',
          message: __('Please provide a valid name and email address before starting the chat.'),
        },
      }
    end

    create_session(chat_id: @payload['data']['chat_id'], name: name, email: email, ticket_id: nil, self_service: false)
  end

  private

  # Fase 6 -- Live Chat Follow-Up Tiket untuk Semua User Login.
  # docs/DESIGN_CHAT_SELF_SERVICE.md Section 5.2. Chat cuma untuk
  # FOLLOW-UP tiket yang SUDAH ADA -- BUKAN cara baru bikin tiket
  # (beda dari Item 5 di atas, yang bikin tiket BARU untuk visitor
  # anonim). `ticket_id` WAJIB & divalidasi ULANG di server (bukan
  # cuma percaya UI, yang harusnya sudah memfilter tapi payload
  # WebSocket bisa dipanggil langsung/dimanipulasi).
  def self_service_init
    if !Setting.get('chat_self_service_enabled')
      return {
        event: 'chat_session_init',
        data:  { state: 'failed', message: __('Live chat is not available right now.') },
      }
    end

    chat_user = User.find_by(id: @session['id'])
    ticket    = Ticket.find_by(id: @payload['data']['ticket_id'])

    if !chat_user || !ticket || ticket.customer_id != chat_user.id || ticket.state.state_type.name.in?(%w[closed merged])
      return {
        event: 'chat_session_init',
        data:  { state: 'failed', message: __('This ticket is not available for chat follow-up.') },
      }
    end

    chat_id = resolve_self_service_chat_id(ticket)
    if !chat_id || !Chat.exists?(id: chat_id, active: true)
      return {
        event: 'chat_session_init',
        data:  { state: 'failed', message: __('Live chat is not available right now.') },
      }
    end

    # Identitas dari AKUN ASLI, bukan payload -- user yang login tidak
    # bisa menyamar pakai nama/email orang lain. Manfaat tambahan:
    # tiket hasil chat (kalau ada, di sini SUDAH ada) tetap tertaut ke
    # akun SISKA asli lewat email yang sama, bukan bikin identitas baru.
    create_session(
      chat_id:      chat_id,
      name:         chat_user.fullname,
      email:        chat_user.email,
      ticket_id:    ticket.id,
      self_service: true,
    )
  end

  # Fase 6 -- docs/DESIGN_CHAT_SELF_SERVICE.md Section 5.6. Routing
  # configurable: coba arahkan ke topik chat milik Group pemilik
  # tiket KALAU sudah dikonfigurasi admin (lewat `ticket_group_id`
  # yang SUDAH ADA di preferences tiap topik Chat sejak Fase 5,
  # Section 5.1.3 -- dipakai ULANG di sini untuk arah sebaliknya,
  # bukan Setting mapping baru), fallback ke topik default
  # (`chat_self_service_chat_id`) kalau tidak ketemu ATAU topiknya ada
  # tapi TIDAK ADA agent yang aktif di situ (supaya user tidak macet
  # kalau departemen tujuan belum standby).
  def resolve_self_service_chat_id(ticket)
    default_chat_id = Setting.get('chat_self_service_chat_id')
    return default_chat_id if !Setting.get('chat_self_service_route_by_ticket_group')

    matching_chat = Chat.where(active: true).find do |chat|
      chat.preferences[:ticket_group_id].present? && chat.preferences[:ticket_group_id].to_i == ticket.group_id
    end
    return default_chat_id if !matching_chat
    return default_chat_id if Chat.active_agent_count([matching_chat.id]).zero?

    matching_chat.id
  end

  # Dipakai KEDUA jalur (widget anonim & follow-up user login) --
  # cuma beda ASAL name/email/ticket_id/self_service, sisanya
  # (geo/dns lookup, pembuatan Chat::Session, broadcast, balasan
  # queue) identik, jadi dipusatkan di sini bukan diduplikasi.
  def create_session(chat_id:, name:, email:, ticket_id:, self_service:)
    # geo ip lookup
    geo_ip = nil
    if remote_ip
      geo_ip = Service::GeoIp.location(remote_ip)
    end

    # dns lookup
    dns_name = nil
    if remote_ip
      begin
        dns = Resolv::DNS.new
        dns.timeouts = 3
        result = dns.getname remote_ip
        if result
          dns_name = result.to_s
        end
      rescue => e
        Rails.logger.error e
      end
    end

    # create chat session
    chat_session = Chat::Session.create(
      chat_id:     chat_id,
      name:        name,
      email:       email,
      ticket_id:   ticket_id,
      state:       'waiting',
      preferences: {
        url:          @payload['data']['url'],
        participants: [@client_id],
        remote_ip:    remote_ip,
        geo_ip:       geo_ip,
        dns_name:     dns_name,
        self_service: self_service,
      },
    )

    # send broadcast to agents
    Chat.broadcast_agent_state_update([chat_session.chat_id])

    # return new session
    {
      event: 'chat_session_queue',
      data:  {
        state:      'queue',
        position:   Chat.waiting_chat_count([chat_session.chat_id]),
        session_id: chat_session.session_id,
      },
    }
  end

end
