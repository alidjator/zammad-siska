# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::ChatSessionClose < Sessions::Event::ChatBase

=begin

a agent or customer is closing the chat session

payload

  {
    event: 'chat_session_close',
    data: {},
  }

return is sent as message back to peer

=end

  def run
    return super if super

    return if !check_chat_session_exists

    realname = 'Anonymous'

    # if it is a agent session, use the realname if the agent for close message
    chat_session = current_chat_session

    # Atas permintaan user ("feedback rating berlaku kalau agent
    # menutup sesi dengan mengklik tombol close di sisi agent, bukan
    # karena status socket") -- `@session` HANYA terisi kalau pemanggil
    # event INI (`chat_session_close`) adalah user Zammad TERAUTENTIKASI
    # (sisi app agent, `.js-disconnect` -> `disconnect()` di
    # `app/assets/javascripts/app/controllers/chat.coffee`) -- widget
    # customer anonim TIDAK PERNAH punya `@session` sama sekali. Jadi
    # nilai ini SUDAH SECARA ALAMI hanya `true` utk klik tombol
    # deliberate di sisi agent, TIDAK PERNAH utk `Chat.cleanup_close`
    # (scheduler pasif, lihat `app/models/chat.rb`, path KODE TERPISAH
    # yang TIDAK PERNAH lewat event handler ini sama sekali) MAUPUN
    # socket agent yang putus/reload TANPA klik (kasus itu TIDAK
    # PERNAH memicu event `chat_session_close` ini sama sekali -- sesi
    # baru benar2 ditutup belakangan oleh scheduler di atas).
    closed_by_agent = !!(@session && @session['id'])
    if closed_by_agent && chat_session.user_id
      agent_user = chat_session.agent_user
      if agent_user[:name]
        realname = agent_user[:name]
      end
    end

    # check count of participents
    participents_count = 0
    if chat_session.preferences[:participents]
      participents_count = chat_session.preferences[:participents].count
    end

    # notify about "closing"
    if participents_count < 2 || (@session && chat_session.user_id == @session['id'])
      message = {
        event: 'chat_session_closed',
        data:  {
          session_id:      chat_session.session_id,
          realname:        realname,
          closed_by_agent: closed_by_agent,
        },
      }

      # close session if host is closing it
      chat_session.state = 'closed'
      chat_session.save

      # set state update to all agents
      Chat.broadcast_agent_state_update([chat_session.chat_id])

      # send position update to other waiting sessions
      Chat.broadcast_customer_state_update(chat_session.chat_id)

    # notify about "leaving"
    else
      message = {
        event: 'chat_session_left',
        data:  {
          session_id: chat_session.session_id,
          realname:   realname,
        },
      }
    end
    chat_session.send_to_recipients(message, @client_id)

    # notifiy participients
    {
      event: 'chat_status_close',
      data:  {
        state:      'ok',
        session_id: chat_session.session_id,
      },
    }
  end

end
