# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 5 -- Item No. 6 (Live Chat Enhancement, Attachment). See
# docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.2.1. SENGAJA TIDAK
# pakai `authenticate_and_authorize!` -- visitor Live Chat anonim,
# tidak pernah login sebagai user Zammad. Otorisasi di sini berbasis
# KEPEMILIKAN SESI (session_id chat yang valid & masih aktif), bukan
# token/akun -- preseden yang sama sudah dipakai proyek ini sendiri di
# halaman feedback CSAT publik (Fase 1).
#
# Endpoint ini dipakai KEDUA sisi (widget customer & panel agent) --
# `current_user` (otentikasi Zammad NORMAL, kalau ada) menentukan
# apakah upload ini dari agent yang sedang login atau dari customer
# anonim, tanpa perlu parameter tambahan.
class ChatAttachmentsController < ApplicationController

  # Mengikuti preseden yang sama seperti FeedbackController (Fase 1,
  # halaman CSAT publik) & native Zammad FormController -- endpoint
  # publik/tanpa-login TIDAK bisa memakai token CSRF berbasis sesi
  # cookie (visitor chat tidak pernah punya sesi Zammad sama sekali).
  skip_before_action :verify_csrf_token

  # Fase 7 -- celah CORS ditemukan saat riset (lihat
  # docs/DESIGN_WIDGET_HOME_MESSAGES_HELP.md Section 2.2/5.4).
  # `ApplicationController::SetsHeaders#set_access_control_headers`
  # (sudah otomatis ke-include lewat ApplicationController) HANYA
  # mengirim header CORS untuk request ber-autentikasi token/basic --
  # visitor chat anonim (TIDAK PERNAH login, lihat komentar di atas)
  # sama sekali tidak dapat header ini, jadi browser MEMBLOKIR
  # response-nya kalau widget ditempel di domain lain (beda origin
  # dari server SISKA, kondisi produksi sebenarnya). `cors_preflight_check`
  # (before_action) sendiri SUDAH otomatis ter-include & sudah cukup
  # untuk preflight OPTIONS -- yang kurang cuma header di response
  # SESUNGGUHNYA (GET/POST). Mengikuti preseden native
  # `FormController` (endpoint publik/anonim lain yang sudah benar):
  # override tanpa syarat lewat `set_access_control_headers_execute`.
  after_action :set_access_control_headers_execute

  # `authentication_check_only` (BUKAN `authenticate_and_authorize!`)
  # -- MENCOBA resolusi user kalau ada kredensial valid (token/sesi
  # agent), tapi TIDAK memaksa gagal kalau tidak ada sama sekali
  # (visitor chat anonim). Tanpa ini, `current_user` di bawah SELALU
  # nil bahkan untuk request agent yang sudah login -- `current_user`
  # cuma reader polos, populasinya adalah EFEK SAMPING memanggil salah
  # satu method otentikasi ini (dikonfirmasi lewat pembacaan
  # `application_controller/authenticates.rb`/`has_user.rb`).
  prepend_before_action :authentication_check_only

  MAX_SIZE_MB_HARD_CAP = 20
  # Ekstensi berbahaya SELALU ditolak, TIDAK BISA dilonggarkan lewat
  # Setting `chat_attachment_allowed_extensions` apa pun isinya.
  DENYLIST_EXTENSIONS = %w[exe bat cmd sh ps1 js html htm php jar msi com scr vbs].freeze

  # GET /api/v1/chat_sessions/:session_id/attachments/:id
  # Dipakai widget customer & panel agent dua-duanya untuk menampilkan
  # kembali/mengunduh attachment yang sudah terkirim -- otorisasi SAMA
  # seperti upload (kepemilikan session_id), bukan token/akun, supaya
  # customer anonim yang refresh halaman chat-nya tetap bisa melihat
  # attachment yang dia kirim sendiri sebelumnya.
  def show
    chat_session = Chat::Session.find_by(session_id: params[:session_id])
    return head(:not_found) if !chat_session

    chat_message = Chat::Message.find_by(id: params[:id], chat_session_id: chat_session.id)
    return head(:not_found) if !chat_message

    store = Store.list(object: 'Chat::Message', o_id: chat_message.id).first
    return head(:not_found) if !store

    # Atas permintaan user (widget customer: "jangan tampilkan link
    # aslinya, tombol download saja") -- default TETAP 'inline' (perilaku
    # LAMA, dipakai jg oleh panel agent lewat endpoint yg SAMA, lihat
    # komentar kelas di atas -- TIDAK disentuh). Param baru `disposition`
    # (whitelist EKSPLISIT, cuma 'attachment' yg diterima, apa pun nilai
    # lain jatuh ke default) -- tombol download widget MEMINTA
    # `?disposition=attachment` secara eksplisit supaya browser BENAR-
    # BENAR mengunduh (bukan cuma buka tab baru) WALAU widget di-embed
    # lintas-domain -- atribut HTML `download` SENDIRIAN tidak cukup utk
    # ini (browser mengabaikannya utk link lintas-origin, beda dari
    # header `Content-Disposition` yg dikirim server di sini, yg
    # dihormati browser TERLEPAS dari origin).
    disposition = params[:disposition] == 'attachment' ? 'attachment' : 'inline'

    send_data(
      store.content,
      filename:    store.filename,
      type:        store.preferences['Content-Type'] || 'application/octet-stream',
      disposition: disposition,
    )
  end

  # POST /api/v1/chat_sessions/:session_id/attachments
  def create
    chat_session = Chat::Session.find_by(session_id: params[:session_id])
    return render(json: { error: __('Invalid or expired chat session.') }, status: :not_found) if !chat_session || chat_session.state == 'closed'

    return render(json: { error: __('Attachments are not enabled for this conversation.') }, status: :forbidden) if !chat_session.attachment_enabled?

    file = params[:File]
    return render(json: { error: __('No file provided.') }, status: :unprocessable_content) if !file

    extension = File.extname(file.original_filename).delete_prefix('.').downcase
    if DENYLIST_EXTENSIONS.include?(extension)
      return render(json: { error: __('This file type is not allowed.') }, status: :unprocessable_content)
    end

    allowed = Setting.get('chat_attachment_allowed_extensions').to_s.split(',').map { |e| e.strip.downcase }
    if allowed.exclude?(extension)
      return render(json: { error: __('This file type is not allowed.') }, status: :unprocessable_content)
    end

    max_size_mb = [Setting.get('chat_attachment_max_size_mb').to_i, MAX_SIZE_MB_HARD_CAP].min
    max_size_mb = MAX_SIZE_MB_HARD_CAP if max_size_mb <= 0
    max_size_bytes = max_size_mb.megabytes

    data = file.read
    if data.bytesize > max_size_bytes
      return render(json: { error: __('File is too large (max %s MB).') % max_size_mb }, status: :unprocessable_content)
    end

    scan_result = Service::Chat::VirusScan.scan(data)
    case scan_result
    when :infected
      return render(json: { error: __('This file was flagged as unsafe and was not uploaded.') }, status: :unprocessable_content)
    when :unavailable
      # fail-CLOSED yang disengaja -- lihat docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md
      # Section 5.2.5. Kalau ClamAV SUDAH dikonfigurasi tapi tidak bisa
      # dihubungi, upload ditolak, BUKAN diam-diam diloloskan tanpa
      # dipindai.
      return render(json: { error: __('Attachment scanning service is currently unavailable, please try again shortly.') }, status: :service_unavailable)
    end
    # :skipped (belum dikonfigurasi) dan :clean sama-sama lanjut.

    content_type = file.content_type.presence || 'application/octet-stream'

    # Dipaksa eksplisit -- dikonfirmasi lewat pengujian langsung bahwa
    # `UserInfo.current_user_id` ambient di jalur controller HTTP biasa
    # (beda dari jalur WebSocket event Sessions::Event, yang mengelola
    # sendiri & reset ke nil tiap event) bisa saja sudah keburu terisi
    # sebelum baris ini -- tanpa dipaksa ulang di sini, `created_by_id`
    # customer anonim bisa salah tercatat sebagai user lain.
    UserInfo.current_user_id = current_user&.id

    chat_message = Chat::Message.create!(
      chat_session_id: chat_session.id,
      content:         '[attachment]',
      created_by_id:   current_user&.id,
    )

    # `stores.created_by_id` NOT NULL -- beda dari `chat_messages`
    # (nullable, sengaja dibiarkan nil untuk pesan customer anonim,
    # konsisten dengan alur WebSocket teks di ChatSessionMessage).
    # Fallback ke user System (id 1) kalau tidak ada user login sama
    # sekali -- konvensi yang sama dipakai Zammad sendiri untuk konten
    # tanpa aktor manusia yang jelas.
    store = Store.create!(
      object:        'Chat::Message',
      o_id:          chat_message.id,
      data:          data,
      filename:      file.original_filename,
      preferences:   { 'Content-Type' => content_type },
      created_by_id: current_user&.id || 1,
    )

    broadcast = {
      event: 'chat_session_attachment',
      data:  {
        session_id: chat_session.session_id,
        message:    chat_message.attributes.merge(
          filename:     store.filename,
          size:         store.size,
          content_type: content_type,
          store_id:     store.id,
        ),
      },
    }
    chat_session.send_to_recipients(broadcast)

    # Enhancement 4 (item lampiran OfflineCompose) -- logika sinkron
    # DIPINDAH ke `Chat::Session#sync_attachment_to_ticket!` (badan
    # identik) supaya method yang SAMA bisa dipakai ULANG utk sinkron
    # RETROAKTIF saat tiket pesan offline baru lahir (lihat
    # `Chat::Session#sync_pending_attachments_to_ticket!` -- tiket
    # belum tentu ada SAAT upload ini utk sesi offline, beda dgn chat
    # biasa yang tiketnya sudah pasti ada di titik ini).
    chat_session.sync_attachment_to_ticket!(chat_message)

    render json: {
      id:           chat_message.id,
      filename:     store.filename,
      size:         store.size,
      content_type: content_type,
    }, status: :created
  end

end
