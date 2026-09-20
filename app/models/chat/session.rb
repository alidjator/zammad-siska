# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Chat::Session < ApplicationModel
  include HasSearchIndexBackend
  include CanSelector
  include HasTags

  include Chat::Session::Search
  include Chat::Session::SearchIndex
  include Chat::Session::Assets

  # rubocop:disable Rails/InverseOf
  has_many   :messages, class_name: 'Chat::Message', foreign_key: 'chat_session_id', dependent: :delete_all
  belongs_to :user,     class_name: 'User', optional: true
  belongs_to :chat,     class_name: 'Chat'
  # Fase 5, Item No. 5 -- docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.1.
  # Ticket auto-created when an agent accepts this chat session.
  belongs_to :ticket,   class_name: 'Ticket', optional: true
  # rubocop:enable Rails/InverseOf

  before_create :generate_session_id

  store :preferences

  # Fase 5 -- Item No. 6, fitur tambahan enable/disable attachment
  # global + per-agent. docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section
  # 5.2.6. Dipusatkan di sini (bukan diulang di
  # ChatAttachmentsController & ChatSessionStart) karena KEDUA tempat
  # itu butuh logika PERSIS sama -- 2 lapis, DUA-DUANYA harus lolos:
  #
  # 1. Saklar GLOBAL `chat_attachment_enabled` (default NYALA) -- admin
  #    mematikan ini = attachment nonaktif total untuk SEMUA agent.
  # 2. Preferensi AGENT yang menerima sesi ini (`user_id`), disimpan di
  #    `preferences[:chat][:attachment_enabled]` -- pola yang SAMA
  #    dengan `preferences[:chat][:active]` yang sudah ada untuk topik
  #    chat. Default NONAKTIF (beda dari saklar global) -- agent harus
  #    mengaktifkannya sendiri dulu lewat Chat Settings.
  #
  # Kalau sesi belum punya agent (`user_id` masih kosong -- customer
  # masih di antrean), attachment DITOLAK -- preferensi agent belum
  # bisa dicek sama sekali di titik ini.
  def attachment_enabled?
    return false if !Setting.get('chat_attachment_enabled')
    return false if user_id.blank?

    agent = User.lookup(id: user_id)
    return false if !agent

    !!agent.preferences.dig(:chat, :attachment_enabled)
  end

  # Fase 5 -- Riwayat Chat Sebelumnya. docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md
  # Section 5.1.7. Dipusatkan DI SINI (bukan cuma method privat di
  # `Sessions::Event::ChatSessionStart`) -- BUG NYATA ditemukan lewat
  # laporan user + reproduksi Puppeteer: sebelumnya field ini cuma
  # dihitung & dikirim SEKALI, saat `ChatSessionStart#run` (agent accept
  # chat baru). Jendela chat yang RECONNECT (lewat heartbeat/reload
  # halaman, `Chat.active_chats_by_user_id` di bawah) membangun ulang
  # data sesi TANPA lewat `ChatSessionStart` sama sekali, sehingga
  # `previous_sessions` hilang TOTAL begitu agent reload halaman untuk
  # chat yang masih berjalan -- padahal transkrip lama (isi pesan)
  # baru pertama kali muncul di titik reload itulah yang paling sering
  # dicoba user. Dipindah ke method instance di sini supaya BISA
  # dipanggil dari kedua jalur (accept baru maupun reconnect), bukan
  # diduplikasi/dibiarkan cuma di satu jalur.
  def previous_sessions_summary
    return [] if email.blank?

    Chat::Session
      .where(email: email)
      .where.not(id: id)
      .order(created_at: :desc)
      .limit(5)
      .map { |session| session.send(:previous_session_summary_entry) }
  end

  # Enhancement 1 -- Tahap 2 (fondasi). Method ini SEBELUMNYA method
  # PRIVAT di `Sessions::Event::ChatSessionStart` (`create_ticket_for_
  # chat_session`, Fase 5 Item No. 5), dipindah ke sini SUPAYA bisa
  # dipakai ULANG dari event pesan-offline (Enhancement 1 -- Tahap 3,
  # tidak ada agent yang "Accept" utk memicunya spt chat biasa).
  #
  # Parameter `article:` DITAMBAHKAN di Tahap 3 -- kebutuhan KONKRET
  # (bukan spekulatif): pesan offline butuh artikel pertama tiket
  # berisi PESAN VISITOR SENDIRI (sender Customer, type web), BEDA
  # dari chat biasa yang cuma catatan sistem generik "Live chat
  # dimulai.". Default param (`nil`) mereproduksi PERSIS perilaku
  # lama -- pemanggil chat biasa (`chat_session_start.rb`) TIDAK
  # PERLU diubah sama sekali.
  def create_ticket_for_chat!(article: nil)
    return if ticket_id.present?

    group_id = chat.preferences[:ticket_group_id] || Setting.get('chat_auto_ticket_group_id')
    if group_id.blank?
      Rails.logger.info "Live Chat auto-ticket dilewati untuk sesi #{session_id} -- chat_auto_ticket_group_id belum dikonfigurasi."
      return
    end

    customer = Channel::Filter::BaseIdentifyUser.user_create(
      email:     email,
      firstname: name.presence || email,
      lastname:  '',
    )

    # Bug ditemukan lewat pengujian LANGSUNG (rails runner, bukan lewat
    # WS sungguhan) saat menyiapkan Tahap 3: `Ticket`/`Ticket::Article`
    # WAJIB `created_by_id`/`updated_by_id` (NOT NULL) -- utk chat
    # BIASA ini SELALU aman krn dipanggil dari konteks agent yang
    # sedang login (`UserInfo.current_user_id` ambient TERISI otomatis
    # oleh dispatcher WS), TAPI utk pesan OFFLINE (Tahap 3) pemanggilnya
    # visitor ANONIM -- TIDAK ADA user login sama sekali, ambient itu
    # kosong. `user_id` (agent yang menerima sesi ini, kalau ada) jadi
    # aktor; fallback ke user System (id 1) kalau kosong -- preseden
    # SAMA PERSIS dgn `chat_attachments_controller.rb`.
    actor_id = user_id.presence || 1

    ticket = Ticket.create!(
      title:         "Live Chat - #{name.presence || email}",
      group_id:      group_id,
      customer_id:   customer.id,
      created_by_id: actor_id,
      updated_by_id: actor_id,
    )

    article ||= {
      type_name:   'chat',
      sender_name: 'System',
      from:        name.presence || email,
      body:        __('Live chat dimulai.'),
    }

    Ticket::Article.create!(
      ticket_id:     ticket.id,
      type:          Ticket::Article::Type.find_by(name: article[:type_name]),
      sender:        Ticket::Article::Sender.find_by(name: article[:sender_name]),
      from:          article[:from],
      body:          article[:body],
      internal:      false,
      created_by_id: actor_id,
      updated_by_id: actor_id,
    )

    update!(ticket_id: ticket.id)
  rescue => e
    Rails.logger.error "Live Chat auto-ticket gagal dibuat untuk sesi #{session_id}: #{e.message}"
  end

  # Enhancement 1 -- Tahap 3 (Offline Message + Verifikasi OTP). Dipakai
  # KEDUA jalur yang butuh kode baru (`chat_offline_session_init` --
  # pengiriman PERTAMA -- dan `chat_offline_otp_resend`) supaya
  # logikanya SATU tempat, tidak diduplikasi. Kode disimpan sbg HASH
  # (`Digest::SHA256`) -- lihat komentar migrasi `otp_code` utk
  # alasannya.
  def generate_and_send_otp!
    code = format('%06d', SecureRandom.random_number(1_000_000))
    expiry_minutes = Setting.get('chat_offline_otp_expiry_minutes').to_i

    update!(
      otp_code:         Digest::SHA256.hexdigest(code),
      otp_expires_at:   expiry_minutes.minutes.from_now,
      otp_code_sent_at: Time.zone.now,
      otp_verified_at:  nil,
      otp_attempts:     0,
    )

    deliver_otp_email(code, expiry_minutes)
    true
  end

  # Hasil balik berupa simbol (bukan boolean) SENGAJA -- pemanggil
  # (`chat_offline_otp_verify.rb`) perlu tahu ALASAN gagal (kedaluwarsa
  # vs kode salah vs sudah kehabisan percobaan) utk balas pesan error
  # yang tepat ke widget, bukan cuma "gagal" generik.
  def verify_otp(code)
    return :expired if otp_expires_at.blank? || otp_expires_at < Time.zone.now
    return :too_many_attempts if otp_attempts >= Setting.get('chat_offline_otp_max_attempts').to_i

    if otp_code != Digest::SHA256.hexdigest(code.to_s.strip)
      increment!(:otp_attempts)
      return :incorrect
    end

    update!(otp_verified_at: Time.zone.now)
    :verified
  end

  private

  def deliver_otp_email(code, expiry_minutes)
    NotificationFactory::Mailer.deliver(
      recipient:    { id: nil, email: email },
      subject:      __('Kode verifikasi SISKA Live Chat'),
      body:         format(__("Halo,\n\nKode verifikasi Anda: %<code>s\n\nKode ini berlaku selama %<minutes>s menit. Kalau Anda tidak meminta kode ini, abaikan email ini."), code: code, minutes: expiry_minutes),
      content_type: 'text/plain',
    )
  rescue => e
    Rails.logger.error "Enhancement 1 -- gagal kirim email OTP ke #{email} (sesi #{session_id}): #{e.message}"
  end

  public

  def agent_user
    return if user_id.blank?

    user = User.lookup(id: user_id)
    return if user.blank?

    fullname = user.fullname
    chat_preferences = user.preferences[:chat] || {}
    if chat_preferences[:alternative_name].present?
      fullname = chat_preferences[:alternative_name]
    end
    url = nil
    if user.image && user.image != 'none' && chat_preferences[:avatar_state] != 'disabled'
      url = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/api/v1/users/image/#{user.image}"
    end
    {
      name:   fullname,
      avatar: url,
    }
  end

  def generate_session_id
    self.session_id = Digest::MD5.hexdigest(SecureRandom.uuid)
  end

  def add_recipient(client_id, store = false)
    if !preferences[:participants]
      preferences[:participants] = []
    end
    return preferences[:participants] if preferences[:participants].include?(client_id)

    preferences[:participants].push client_id
    if store
      save
    end
    preferences[:participants]
  end

  def recipients_active?
    return true if !preferences
    return true if !preferences[:participants]

    count = 0
    preferences[:participants].each do |client_id|
      next if !Sessions.session_exists?(client_id)

      count += 1
    end
    return true if count >= 2

    false
  end

  def send_to_recipients(message, ignore_client_id = nil)
    preferences[:participants].each do |local_client_id|
      next if local_client_id == ignore_client_id

      Sessions.send(local_client_id, message)
    end
    true
  end

  def position
    return if state != 'waiting'

    position = 0
    Chat::Session.where(state: 'waiting').reorder(created_at: :asc).each do |chat_session|
      position += 1
      break if chat_session.id == id
    end
    position
  end

  def self.messages_by_session_id(session_id)
    chat_session = Chat::Session.find_by(session_id: session_id)
    return if !chat_session

    chat_session
      .messages
      .reorder(created_at: :asc)
      .map { |message| enrich_message_attributes(message) }
  end

  def self.active_chats_by_user_id(user_id)
    actice_sessions = []
    Chat::Session.where(state: 'running', user_id: user_id).reorder(created_at: :asc).each do |session|
      session_attributes = session.attributes
      session_attributes['messages'] = []
      Chat::Message.where(chat_session_id: session.id).reorder(created_at: :asc).each do |message|
        session_attributes['messages'].push enrich_message_attributes(message)
      end
      # Fase 5 -- lihat komentar `previous_sessions_summary` di atas.
      # Disertakan JUGA di jalur reconnect ini (bukan cuma accept
      # pertama kali), supaya bertahan lewat reload halaman.
      session_attributes['previous_sessions'] = session.previous_sessions_summary
      actice_sessions.push session_attributes
    end
    actice_sessions
  end

  # Bug ditemukan lewat laporan user (screenshot widget customer: hard
  # refresh -> kutipan "Membalas: ..." hilang dari bubble pesan yang
  # SEBELUM reload sempat tampil dgn kutipan) -- `.map(&:attributes)`
  # yang dipakai KEDUA method riwayat di atas cuma menyertakan kolom
  # mentah (`reply_to_id` sbg angka polos), BUKAN isi pesan yang
  # direferensikan -- pola bug yang PERSIS SAMA sudah pernah ditemukan
  # & diperbaiki utk jalur REAL-TIME (`chat_session_message.rb`, Fase
  # 5), TAPI jalur RIWAYAT/BULK (method di atas, dipakai widget
  # customer maupun jendela agent) TIDAK PERNAH ikut diperbaiki dgn
  # cara yang sama. Diterapkan ULANG di sini (bukan logika baru).
  #
  # Bug KEDUA ditemukan lewat pengujian LANGSUNG (bukan cuma laporan
  # user) saat menyiapkan fitur reply-pada-attachment: pesan attachment
  # SETELAH reload tampil sbg bubble teks POLOS berbunyi literal
  # "[attachment]" (isi kolom `content` apa adanya, lihat
  # `chat_attachments_controller.rb`) TANPA link unduh sama sekali --
  # frontend (`onReopenSession`) tidak punya cara membedakan pesan
  # attachment dari pesan teks biasa di riwayat, krn keduanya SAMA-SAMA
  # cuma `Chat::Message` polos (attachment yg sesungguhnya disimpan
  # TERPISAH sbg `Store`, bukan kolom di `chat_messages`). Disertakan
  # `filename` di sini (ADA-nya field ini dipakai frontend sbg penanda
  # "pesan ini attachment") kalau ada `Store` terkait -- KEHADIRAN
  # attachment tetap terdeteksi walau isi pesannya kosong/generik.
  def self.enrich_message_attributes(message)
    attrs = message.attributes
    if message.reply_to.present?
      # Atas permintaan user: kutipan pesan attachment pakai nama file
      # aslinya (`Chat::Message#display_content`), bukan literal
      # `'[attachment]'` yg tersimpan di kolom `content` -- konsisten
      # dgn perbaikan yg sama di `chat_session_message.rb`.
      attrs['reply_to'] = { 'content' => message.reply_to.display_content }
    end
    store = Store.list(object: 'Chat::Message', o_id: message.id).first
    if store
      attrs['filename'] = store.filename
    end
    attrs
  end
  private_class_method :enrich_message_attributes

  private

  def previous_session_summary_entry
    messages = self.messages.reorder(created_at: :asc).map do |message|
      {
        content:       message.content,
        is_from_agent: message.created_by_id.present? && message.created_by_id == user_id,
        created_at:    message.created_at,
      }
    end

    {
      created_at: created_at,
      ticket_id:  ticket_id,
      messages:   messages,
    }
  end
end
