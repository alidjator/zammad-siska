# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::ChatSessionInit < Sessions::Event::ChatBase

=begin

a customer requests a new chat session

payload

  {
    event: 'chat_session_init',
    data: {
      chat_id: 'the id of chat',
      url: 'the browser url',
      name: 'the customer name (Fase 5 -- wajib, lihat DESIGN_LIVE_CHAT_ENHANCEMENT.md 5.1.1)',
      email: 'the customer email (Fase 5 -- wajib)',
    },
  }

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
      chat_id:     @payload['data']['chat_id'],
      name:        name,
      email:       email,
      state:       'waiting',
      preferences: {
        url:          @payload['data']['url'],
        participants: [@client_id],
        remote_ip:    remote_ip,
        geo_ip:       geo_ip,
        dns_name:     dns_name,
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
