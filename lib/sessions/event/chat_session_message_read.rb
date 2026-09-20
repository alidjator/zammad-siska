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

    # Cuma AGENT (user login) yang bisa menandai pesan CUSTOMER sebagai
    # terbaca -- customer menandai pesannya sendiri "terbaca" tidak
    # masuk akal (lihat komentar sama di `chat_session_message.rb`
    # utk pola pengecekan `@session['id']` yang identik).
    return if !@session || !@session['id']

    chat_session = current_chat_session

    read_at = Time.zone.now
    updated = Chat::Message.where(chat_session_id: chat_session.id, created_by_id: nil, read_at: nil)
    return if !updated.exists?

    updated.update_all(read_at: read_at)

    message = {
      event: 'chat_session_message_read',
      data:  {
        session_id: chat_session.session_id,
        read_at:    read_at,
      },
    }

    # send to participents
    chat_session.send_to_recipients(message, @client_id)

    # send back to agent itself
    {
      event: 'chat_session_message_read',
      data:  {
        session_id:   chat_session.session_id,
        read_at:      read_at,
        self_written: true,
      },
    }
  end

end
