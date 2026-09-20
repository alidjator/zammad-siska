# Enhancement 4 -- "buatkan semua frase dalam widget configurable bisa
# di setting ... berikan nilai defaultnya untuk semua frasa". Nilai
# default DI BAWAH = teks yang SUDAH LIVE di widget saat ini (bahasa
# Inggris) -- disepakati dgn user utk TIDAK mengubah bahasa/tampilan
# yang sudah berjalan, murni menjadikannya configurable.
#
# Dikecualikan dari daftar ini (sesuai cakupan yg disepakati, lihat
# docs/ACTIVITY_LOG_SISKA.md entri Enhancement 4):
# - nama tab (Home/Messages/Help) & semua aria-label ikon (bukan teks
#   yg terlihat)
# - isi percakapan chat sungguhan & pengumuman status koneksi/sistem
#   ("Connection lost", "Chat closed by %s", label tanggal "Today",
#   dll) -- ini teks sistem/dinamis, bukan copy branding
# - SELURUH konten halaman Help yg bersumber dari knowledgebase
# - `scrollHint` -- sudah punya mekanisme configurable SENDIRI lewat
#   opsi init widget (`new ZammadChat({ scrollHint: '...' })`)
# - pesan error yg di-generate BACKEND Ruby (`__()` di
#   lib/sessions/event/chat_offline_*.rb) -- scope backend i18n
#   terpisah, follow-up candidate, BUKAN bagian widget frontend ini
#
# Aman dijalankan ulang: ObjectManager/Setting.create_if_not_exists
# style idempoten dipakai via helper `upsert_phrase` di bawah (update
# in place kalau sudah ada, supaya re-run tidak menimpa nilai yg admin
# sudah ubah manual).

UserInfo.current_user_id = 1

def upsert_phrase(name, title, default_value)
  existing = Setting.find_by(name: name)
  if existing
    puts "  (sudah ada, dilewati) #{name}"
    return
  end

  Setting.create!(
    title:       title,
    name:        name,
    area:        'SISKA::WidgetPhrases',
    description: "Frase widget live chat SISKA -- #{title}.",
    options:     {
      form: [
        {
          display: '',
          null:    false,
          name:    name,
          tag:     'input',
        },
      ],
    },
    state:       default_value,
    preferences: {
      permission: ['admin.system'],
    },
    frontend:    false,
  )
  puts "  dibuat: #{name}"
end

puts '== Home =='
upsert_phrase('chat_phrase_home_greeting', 'Home: Sapaan', 'Hi there')
upsert_phrase('chat_phrase_home_subtitle', 'Home: Subjudul', 'How can we help you today?')
upsert_phrase('chat_phrase_home_start_button', 'Home: Tombol mulai chat', 'Send us a message')
upsert_phrase('chat_phrase_home_search_button', 'Home/Help: Tombol/placeholder cari bantuan', 'Search for help')

puts '== Home -- Semua Agent Offline =='
upsert_phrase('chat_phrase_offline_status', 'Offline: Status', "We're offline right now")
upsert_phrase('chat_phrase_offline_notice', 'Offline: Pesan notice di Home', 'All our agents are currently unavailable. Leave your message and email, we will verify it via an OTP code and reply as soon as possible.')
upsert_phrase('chat_phrase_offline_start_button', 'Offline: Tombol mulai pesan offline', 'Leave us a message')

puts '== Prechat (Isi Nama & Email) =='
upsert_phrase('chat_phrase_prechat_title', 'Prechat: Judul', "Let's get started")
upsert_phrase('chat_phrase_prechat_subtitle', 'Prechat: Subjudul', 'Please share a few details so our agent can help you faster.')
upsert_phrase('chat_phrase_prechat_name_label', 'Prechat: Label nama', 'Your name')
upsert_phrase('chat_phrase_prechat_email_label', 'Prechat: Label email', 'Your email')
upsert_phrase('chat_phrase_prechat_submit_button', 'Prechat: Tombol submit', 'Start chat')
upsert_phrase('chat_phrase_prechat_validation_error', 'Prechat: Pesan error validasi', 'Please provide a valid name and email address.')

puts '== Menunggu Agent & Timeout =='
upsert_phrase('chat_phrase_waiting_title', 'Waiting: Judul (dipakai jg di layar connecting)', 'Connecting you to an agent…')
upsert_phrase('chat_phrase_waiting_subtitle', 'Waiting: Subjudul', 'All colleagues are busy.')
upsert_phrase('chat_phrase_waiting_queue_position', 'Waiting: Posisi antrean (%s = angka posisi)', 'You are on waiting list position <strong>%s</strong>.')
upsert_phrase('chat_phrase_waiting_cancel_button', 'Waiting: Tombol batalkan', 'Cancel')
upsert_phrase('chat_phrase_waiting_timeout_message', 'Waiting: Pesan timeout antrean penuh', 'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!')
upsert_phrase('chat_phrase_restart_button', 'Timeout: Tombol mulai percakapan baru', 'Start new conversation')
upsert_phrase('chat_phrase_customer_timeout_with_agent', 'Timeout: Pesan idle DENGAN nama agent (%s menit, %s nama agent)', "Since you didn't respond in the last %s minutes your conversation with <strong>%s</strong> was closed.")
upsert_phrase('chat_phrase_customer_timeout', 'Timeout: Pesan idle TANPA nama agent (%s menit)', "Since you didn't respond in the last %s minutes your conversation was closed.")

puts '== Messages (chat berjalan) =='
upsert_phrase('chat_phrase_messages_agent_status_active', 'Messages: Status agent di header', 'Active now')
upsert_phrase('chat_phrase_messages_compose_placeholder', 'Messages: Placeholder kotak ketik', 'Compose your message…')
upsert_phrase('chat_phrase_messages_reply_prefix', 'Messages: Prefix indikator balas', 'Replying to:')

puts '== Verifikasi OTP =='
upsert_phrase('chat_phrase_otp_title', 'OTP: Judul', 'Enter verification code')
upsert_phrase('chat_phrase_otp_subtitle_prefix', 'OTP: Awal subjudul (diikuti alamat email)', 'We sent a 6-digit code to')
upsert_phrase('chat_phrase_otp_incomplete_error', 'OTP: Error kode belum lengkap', 'Please enter the full 6-digit code.')
upsert_phrase('chat_phrase_otp_verify_button', 'OTP: Tombol verifikasi', 'Verify')
upsert_phrase('chat_phrase_otp_resend_question', 'OTP: Pertanyaan kirim ulang', "Didn't receive the code?")
upsert_phrase('chat_phrase_otp_resend_button', 'OTP: Tombol kirim ulang', 'Resend code')
upsert_phrase('chat_phrase_otp_resend_success', 'OTP: Pesan sukses kirim ulang', 'A new code has been sent.')
upsert_phrase('chat_phrase_otp_resend_error_fallback', 'OTP: Pesan error kirim ulang (fallback)', 'Could not resend code. Please try again.')
upsert_phrase('chat_phrase_otp_change_email', 'OTP: Tombol ganti email', 'Change email address')

puts '== Tulis Pesan Offline =='
upsert_phrase('chat_phrase_offline_compose_verified_suffix', 'Offline Compose: Akhiran badge terverifikasi (setelah alamat email)', 'verified')
upsert_phrase('chat_phrase_offline_compose_message_label', 'Offline Compose: Label pesan', 'Your message')
upsert_phrase('chat_phrase_offline_compose_placeholder', 'Offline Compose: Placeholder textarea', 'Tell us how we can help…')
upsert_phrase('chat_phrase_offline_compose_send_button', 'Offline Compose: Tombol kirim', 'Send Message')
upsert_phrase('chat_phrase_offline_compose_empty_error', 'Offline Compose: Error pesan kosong', 'Please write a message.')

puts '== Konfirmasi Pesan Offline Terkirim =='
upsert_phrase('chat_phrase_offline_sent_title', 'Offline Sent: Judul', 'Your message has been sent!')
upsert_phrase('chat_phrase_offline_sent_subtitle_prefix', 'Offline Sent: Awal subjudul (diikuti alamat email)', 'Our team will reply to')
upsert_phrase('chat_phrase_offline_sent_subtitle_suffix', 'Offline Sent: Akhir subjudul (setelah alamat email)', 'as soon as an agent is available.')
upsert_phrase('chat_phrase_offline_sent_button', 'Offline Sent: Tombol lanjut', 'Continue')

puts '== Loading Mengakhiri Percakapan =='
upsert_phrase('chat_phrase_ending_title', 'Ending: Judul', 'Ending conversation…')
upsert_phrase('chat_phrase_ending_subtitle', 'Ending: Subjudul', 'Please wait a moment.')

puts '== Rating Kepuasan (Feedback) =='
upsert_phrase('chat_phrase_feedback_title', 'Feedback: Judul', 'How was your experience?')
upsert_phrase('chat_phrase_feedback_subtitle', 'Feedback: Subjudul', 'Your feedback helps us improve.')
upsert_phrase('chat_phrase_feedback_comment_placeholder', 'Feedback: Placeholder komentar', 'Add a comment (optional)')
upsert_phrase('chat_phrase_feedback_skip_button', 'Feedback: Tombol lewati', 'Maybe later')
upsert_phrase('chat_phrase_feedback_submit_button', 'Feedback: Tombol submit', 'Submit Feedback')
upsert_phrase('chat_phrase_feedback_score_error', 'Feedback: Error belum pilih rating', 'Please select a rating.')
upsert_phrase('chat_phrase_feedback_submit_error_fallback', 'Feedback: Error submit gagal (fallback)', 'Could not save your feedback. Please try again.')
upsert_phrase('chat_phrase_feedback_thanks_title', 'Feedback Thanks: Judul', 'Thank you for your feedback!')
upsert_phrase('chat_phrase_feedback_thanks_subtitle', 'Feedback Thanks: Subjudul', 'We appreciate you taking the time.')

puts '== Help & Lampiran =='
upsert_phrase('chat_phrase_help_no_results', 'Help: Pesan hasil pencarian kosong', 'No results found.')
upsert_phrase('chat_phrase_attachment_upload_error', 'Lampiran: Pesan error upload gagal', 'The attachment could not be uploaded.')

puts 'Done.'
