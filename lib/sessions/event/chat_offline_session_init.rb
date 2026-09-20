# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Enhancement 1 -- Tahap 3 (Offline Message + Verifikasi OTP). Dipicu
# saat visitor mengisi form nama+email di `OfflineHome.dc.html` ->
# reuse `Prechat.dc.html` (mockup), TAPI beda alur dari
# `chat_session_init.rb` biasa -- TIDAK masuk antrean 'waiting', TIDAK
# ada agent yang menunggu. Sesi langsung berstatus 'offline_pending' +
# kode OTP langsung dikirim ke email.
#
# payload
#
#   {
#     event: 'chat_offline_session_init',
#     data: {
#       chat_id: 'the id of chat',
#       url: 'the browser url',
#       name: 'the customer name',
#       email: 'the customer email',
#     },
#   }
#
# return is sent as message back to peer
class Sessions::Event::ChatOfflineSessionInit < Sessions::Event::ChatBase

  EMAIL_FORMAT = %r{\A[^@\s]+@[^@\s]+\.[^@\s]+\z}.freeze

  def run
    return super if super
    return if !check_chat_exists

    # Pertahanan LAPIS KEDUA (server-side) -- WS bisa dipanggil
    # langsung tanpa lewat widget resminya, jadi TIDAK cukup percaya
    # klien sudah benar mendeteksi "semua agent offline". Kalau
    # ternyata ADA agent tersedia (mis. race condition/klien basi),
    # tolak di sini -- customer SEHARUSNYA pakai alur chat biasa.
    if !Chat.active_agent_count([@payload['data']['chat_id']]).zero?
      return {
        event: 'chat_offline_session_init',
        data:  { state: 'failed', message: __('An agent is available -- please use live chat instead.') },
      }
    end

    name  = @payload['data']['name'].to_s.strip
    email = @payload['data']['email'].to_s.strip.downcase

    if name.blank? || email.blank? || !email.match?(EMAIL_FORMAT)
      return {
        event: 'chat_offline_session_init',
        data:  { state: 'failed', message: __('Please provide a valid name and email address.') },
      }
    end

    chat_session = Chat::Session.create!(
      chat_id:     @payload['data']['chat_id'],
      name:        name,
      email:       email,
      state:       'offline_pending',
      preferences: {
        url:          @payload['data']['url'],
        participants: [@client_id],
      },
    )

    chat_session.generate_and_send_otp!

    {
      event: 'chat_offline_session_init',
      data:  {
        state:      'ok',
        session_id: chat_session.session_id,
      },
    }
  end

end
