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
#       category: 'kategori tiket, wajib, salah satu value Chat::Session.category_options',
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
      # `reason: 'agent_available'` -- atas permintaan user, pesan ini
      # BUKAN error sungguhan (kabar BAIK, agent sekarang tersedia),
      # jadi ditampilkan pakai gaya notice SUKSES Able Pro di
      # frontend, BEDA dari pesan gagal validasi nama/email di bawah
      # (`Please provide a valid name and email address.`, TETAP
      # error). `reason` yg membedakan, BUKAN cek isi teks `message`
      # (rapuh kalau frasa-nya nanti diubah).
      return {
        event: 'chat_offline_session_init',
        data:  { state: 'failed', reason: 'agent_available', message: __('An agent is available -- please use live chat instead.') },
      }
    end

    name     = @payload['data']['name'].to_s.strip
    email    = @payload['data']['email'].to_s.strip.downcase
    category = @payload['data']['category'].to_s.strip

    # Atas permintaan user (field Category, wajib sama spt di jalur
    # chat biasa `chat_session_init.rb`) -- sumber kebenaran opsi yang
    # SAMA (`Chat::Session.category_options`), form Prechat/OfflineHome
    # di widget ADALAH satu form yang SAMA (lihat catatan atas file
    # ini), jadi validasinya WAJIB konsisten dgn jalur online.
    if name.blank? || email.blank? || !email.match?(EMAIL_FORMAT) || category.blank? || !Chat::Session.category_options.pluck(:value).include?(category)
      return {
        event: 'chat_offline_session_init',
        data:  { state: 'failed', message: __('Please provide a valid name, email, and category.') },
      }
    end

    chat_session = Chat::Session.create!(
      chat_id:     @payload['data']['chat_id'],
      name:        name,
      email:       email,
      category:    category,
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
