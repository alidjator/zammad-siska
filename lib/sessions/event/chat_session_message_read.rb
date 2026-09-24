# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::ChatSessionMessageRead < Sessions::Event::ChatBase

=begin

an agent has focused/viewed the chat window -- mark all not-yet-read
customer messages of this session as read ("read up to now", bulk --
not per-message granular, matches typical chat-app UX)

payload

  {
    event: 'chat_session_message_read',
    data: {},
  }

return is sent as message back to peer

=end

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session

    # Agent (user login) menandai pesan CUSTOMER sebagai terbaca, seperti
    # sebelumnya. G1 (docs/COMPARISON_WIDGET_VS_AGENT.md): event ini kini
    # juga dikirim CUSTOMER (widget, tanpa sesi login) saat pesan agent
    # benar-benar terlihat olehnya -> pesan AGENT ditandai terbaca. Hanya
    # participant sesi ini yang boleh (pola sama dgn chat_session_reaction.rb).
    # `reader` di broadcast membedakan kedua arah: widget mengabaikan reader
    # 'customer' (tab customer lain), jendela agent hanya memakai 'customer'.
    if @session && @session['id']
      reader = 'agent'
      scope = Chat::Message.where(chat_session_id: chat_session.id, created_by_id: nil)
    else
      return if Array(chat_session.preferences[:participants]).exclude?(@client_id)

      reader = 'customer'
      scope = Chat::Message.where(chat_session_id: chat_session.id).where.not(created_by_id: nil)
    end

    read_at = Time.zone.now
    updated = scope.where(read_at: nil)
    return if !updated.exists?

    updated.update_all(read_at: read_at)

    message = {
      event: 'chat_session_message_read',
      data:  {
        session_id: chat_session.session_id,
        read_at:    read_at,
        reader:     reader,
      },
    }

    # send to participents
    chat_session.send_to_recipients(message, @client_id)

    # send back to the sender itself
    {
      event: 'chat_session_message_read',
      data:  {
        session_id:   chat_session.session_id,
        read_at:      read_at,
        reader:       reader,
        self_written: true,
      },
    }
  end

end
