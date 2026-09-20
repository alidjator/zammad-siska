# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::ChatSessionMessage < Sessions::Event::ChatBase

=begin

a agent or customer creates a new chat session message

payload

  {
    event: 'chat_session_message',
    data: {
      content: 'some message',
      reply_to_id: 123, # opsional -- Fase 5, lihat DESIGN_LIVE_CHAT_ENHANCEMENT.md 5.3
    },
  }

return is sent as message back to peer

=end

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session

    user_id = nil
    if @session
      user_id = @session['id']
    end

    # Fitur tambahan "Reply ke Pesan Spesifik" -- Section 5.3. Validasi
    # keamanan: pesan yang direferensikan HARUS dari sesi chat yang
    # SAMA, supaya satu sesi tidak bisa mereferensikan/membocorkan
    # potongan pesan dari sesi ORANG LAIN lewat id yang
    # ditebak/dimanipulasi -- kalau tidak cocok, reply_to_id diabaikan
    # diam-diam (pesan tetap terkirim, cuma tanpa quote), bukan seluruh
    # pesan ditolak.
    reply_to_id = @payload['data']['reply_to_id']
    if reply_to_id.present?
      reply_to = Chat::Message.find_by(id: reply_to_id, chat_session_id: chat_session.id)
      reply_to_id = reply_to&.id
    end

    chat_message = Chat::Message.create(
      chat_session_id: chat_session.id,
      content:         @payload['data']['content'],
      created_by_id:   user_id,
      reply_to_id:     reply_to_id,
    )

    # Fase 5 -- Item No. 5 (sinkron transkrip real-time ke tiket).
    # Section 5.1.4. Kalau sesi ini sudah terhubung ke tiket (5.1.3),
    # tiap pesan baru JUGA jadi Ticket::Article, supaya tiket tetap
    # hidup mengikuti percakapan.
    sync_message_to_ticket(chat_session, chat_message)

    # BUG DITEMUKAN & DIPERBAIKI (lewat pengujian screenshot end-to-end,
    # bukan cuma baca kode) -- Section 5.3. `chat_message` sebagai
    # object ActiveRecord MENTAH, saat di-serialize ke JSON, HANYA
    # menyertakan kolom (termasuk `reply_to_id` sebagai angka polos),
    # BUKAN isi pesan yang direferensikan. Akibatnya pihak yang
    # MENERIMA balasan (bukan yang mengirim -- pengirim melihat kutipan
    # dari state LOKAL client-nya sendiri, bukan dari broadcast ini)
    # tidak pernah melihat kutipan sama sekali. Diperbaiki dengan
    # menyertakan `reply_to` (cuma `content`, secukupnya untuk potongan
    # kutipan) secara eksplisit di payload.
    message_payload = chat_message.attributes
    if chat_message.reply_to.present?
      # Atas permintaan user: kutipan pesan attachment pakai nama file
      # aslinya (`Chat::Message#display_content`), bukan literal
      # `'[attachment]'` yg tersimpan di kolom `content`.
      message_payload['reply_to'] = { 'content' => chat_message.reply_to.display_content }
    end

    message = {
      event: 'chat_session_message',
      data:  {
        session_id: chat_session.session_id,
        message:    message_payload,
      },
    }

    # send to participents
    chat_session.send_to_recipients(message, @client_id)

    # send chat_session_init to agent
    {
      event: 'chat_session_message',
      data:  {
        session_id:   chat_session.session_id,
        message:      message_payload,
        self_written: true,
      },
    }

  end

  private

  # `created_by_id`/`updated_by_id` DITENTUKAN EKSPLISIT di sini, BUKAN
  # dibiarkan mengandalkan `UserInfo.current_user_id` ambient --
  # pesan CUSTOMER (anonim, tidak pernah login sebagai user Zammad)
  # TIDAK PERNAH punya `UserInfo.current_user_id` sama sekali, jadi
  # kalau dibiarkan mengandalkan itu, sinkronisasi akan SELALU gagal
  # untuk separuh percakapan (giliran customer). Agent yang menerima
  # chat (`chat_session.user_id`) dipakai untuk pesan agent; customer
  # hasil resolusi 5.1.3 (`chat_session.ticket.customer_id`) dipakai
  # untuk pesan customer.
  def sync_message_to_ticket(chat_session, chat_message)
    return if chat_session.ticket_id.blank?

    is_from_agent = chat_message.created_by_id.present? && chat_message.created_by_id == chat_session.user_id
    sender_name   = is_from_agent ? 'Agent' : 'Customer'
    actor_id      = is_from_agent ? chat_session.user_id : chat_session.ticket.customer_id
    from          = is_from_agent ? chat_session.agent_user&.dig(:name) : (chat_session.name.presence || chat_session.email)

    body = chat_message.content
    if chat_message.reply_to.present?
      body = "<blockquote>#{chat_message.reply_to.content}</blockquote>#{body}"
    end

    Ticket::Article.create!(
      ticket_id:     chat_session.ticket_id,
      type:          Ticket::Article::Type.find_by(name: 'chat'),
      sender:        Ticket::Article::Sender.find_by(name: sender_name),
      from:          from,
      body:          body,
      internal:      false,
      created_by_id: actor_id,
      updated_by_id: actor_id,
    )
  rescue => e
    Rails.logger.error "Live Chat gagal sinkron pesan ke tiket #{chat_session.ticket_id}: #{e.message}"
  end

end
