# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::ChatStatusCustomer < Sessions::Event::ChatBase

=begin

a customer requests the current state of a chat

payload

  {
    event: 'chat_status_agent',
    data: {
      session_id: 'the id of the current chat session',
      url: 'optional url', # will trigger a chat_session_notice to agent
    },
  }

return is sent as message back to peer

=end

  def run
    return super if super
    return if !check_chat_exists
    return if blocked_ip?
    return if blocked_country?
    return if blocked_origin?

    # check if it's a chat sessin reconnect
    session_id = nil
    if @payload['data']['session_id']
      session_id = @payload['data']['session_id']

      # update recipients of existing sessions
      chat_session = Chat::Session.find_by(session_id: session_id)
      if chat_session
        chat_session.add_recipient(@client_id, true)

        # sent url update to agent
        if @payload['data']['url']
          message = {
            event: 'chat_session_notice',
            data:  {
              session_id: chat_session.session_id,
              message:    @payload['data']['url'],
            },
          }
          chat_session.send_to_recipients(message, @client_id)
        end
      end
    end

    {
      event: 'chat_status_customer',
      data:  current_chat.customer_state(session_id).merge(logo_url: product_logo_url),
    }
  end

  # Atas permintaan user ("logo pada home mengambil dari setting logo
  # zammad") -- widget disajikan sbg file statis lintas-domain, TIDAK
  # bisa baca `Setting.get('product_logo')` langsung dari SCSS/eco
  # (compile-time, tanpa akses DB) -- disertakan di SINI (payload event
  # yg SUDAH SELALU dikirim ke widget sejak `render()`, lihat
  # chat.coffee) supaya JS bisa isi logo Home secara dinamis SETELAH
  # widget dimuat, bukan bikin event/endpoint baru. URL dibangun manual
  # dari `http_type`/`fqdn` (pola yang SAMA dipakai
  # `chat_knowledge_base_search.rb`), path & param persis preseden
  # NYATA yang sudah ada (`feedback_controller.rb`, satu-satunya
  # pemakai publik/anonim endpoint `system_assets` ini di codebase).
  # `nil` kalau belum ada logo custom diupload -- frontend fallback ke
  # ikon generik yang sudah ada, tidak dipaksa.
  def product_logo_url
    return if Setting.get('product_logo').blank?

    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/api/v1/system_assets/product_logo/#{ERB::Util.url_encode(Setting.get('product_logo'))}"
  end

  def blocked_ip?
    return false if !current_chat.blocked_ip?(remote_ip)

    send_unavailable
    true
  end

  def blocked_country?
    return false if !current_chat.blocked_country?(remote_ip)

    send_unavailable
    true
  end

  def blocked_origin?
    return false if current_chat.website_allowed?(origin)

    send_unavailable
    true
  end

  def send_unavailable
    error = {
      event: 'chat_error',
      data:  {
        state: 'chat_unavailable',
      },
    }
    Sessions.send(@client_id, error)
  end
end
