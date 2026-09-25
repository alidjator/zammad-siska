# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Redesign sisi agent -- riwayat chat di jendela percakapan, gaya WhatsApp
# (mockup "Riwayat chat di jendela percakapan", canvas SISKA Agent - Kit
# Tailwind). Keputusan user: cakupan = semua sesi lain dari EMAIL yang sama
# yang dimulai sebelum sesi ini; per halaman 10 pesan riwayat (percakapan
# saat ini selalu tampil utuh, tidak ikut dihitung); paging dengan scroll
# ke atas lewat `before_id`.

class Sessions::Event::ChatSessionHistory < Sessions::Event::ChatBase

=begin

an agent loads one page of earlier messages from the same customer email

payload

  {
    event: 'chat_session_history',
    data: {
      session_id: '...',   # the session shown in the agent's chat window
      before_id:  123,     # optional: only messages with a smaller id
    },
  }

return is sent as message back to peer

  {
    event: 'chat_session_history',
    data: {
      session_id: '...',
      messages:   [...],   # oldest first, max. PAGE_SIZE
      sessions:   { '<id>' => { ... } },
      has_more:   true,
    },
  }

=end

  def run
    return super if super
    return if !check_chat_session_exists
    return if !permission_check('chat.agent', 'chat')

    chat_session = current_chat_session
    page = chat_session.history_page(before_id: @payload['data']['before_id'], audience: :agent)

    {
      event: 'chat_session_history',
      data:  page.merge(session_id: chat_session.session_id, before_id: @payload['data']['before_id']),
    }
  end

end
