# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Enhancement 1 -- Tahap 3. Dipicu tombol "Kirim Pesan" di
# `OfflineCompose.dc.html`, SETELAH OTP terverifikasi. Aturan
# pembuatan tiket SAMA PERSIS dgn chat biasa ("1 offline message = 1
# tiket") -- reuse penuh `Chat::Session#create_ticket_for_chat!`
# (Enhancement 1 -- Tahap 2), cuma beda artikel pertamanya (isi pesan
# visitor sendiri, bukan catatan sistem generik).
#
# payload
#
#   {
#     event: 'chat_offline_message_send',
#     data: {
#       session_id: 'sesi offline yang sudah terverifikasi OTP-nya',
#       content: 'isi pesan visitor',
#     },
#   }
#
# return is sent as message back to peer
class Sessions::Event::ChatOfflineMessageSend < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session

    if chat_session.state != 'offline_pending'
      return {
        event: 'chat_offline_message_send',
        data:  { state: 'failed', message: __('This session is no longer valid.') },
      }
    end

    # PENTING: validasi OTP diulang DI SINI (bukan cuma dipercaya dari
    # UI) -- WS bisa dipanggil langsung/dimanipulasi lewat console
    # browser, melewati layar OfflineOtp sama sekali.
    if chat_session.otp_verified_at.blank?
      return {
        event: 'chat_offline_message_send',
        data:  { state: 'failed', message: __('Please verify your email first.') },
      }
    end

    content = @payload['data']['content'].to_s.strip
    if content.blank?
      return {
        event: 'chat_offline_message_send',
        data:  { state: 'failed', message: __('Please write a message.') },
      }
    end

    chat_session.create_ticket_for_chat!(
      article: {
        type_name:   'web',
        sender_name: 'Customer',
        from:        chat_session.name.presence || chat_session.email,
        body:        content,
      },
    )

    # `create_ticket_for_chat!` melewati pembuatan tiket dgn AMAN
    # (cuma nge-log) kalau `chat_auto_ticket_group_id` belum
    # dikonfigurasi -- utk chat BIASA itu OK (chat tetap berjalan
    # normal tanpa tiket). Di sini TIDAK ADA "tetap berjalan normal"
    # alternatif -- pesan visitor WAJIB berujung ke tiket supaya ada
    # yang menindaklanjuti, jadi kegagalan ini WAJIB dikabarkan balik.
    if chat_session.ticket_id.blank?
      return {
        event: 'chat_offline_message_send',
        data:  { state: 'failed', message: __('Message could not be sent right now. Please try again later.') },
      }
    end

    chat_session.update!(state: 'closed')

    {
      event: 'chat_offline_message_send',
      data:  {
        state:      'ok',
        session_id: chat_session.session_id,
      },
    }
  end

end
