# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Enhancement 1 -- Tahap 3 (Offline Message + Verifikasi OTP). Semua
# `frontend: false` -- SETTING FUNGSIONAL (angka/perilaku backend),
# BEDA KATEGORI dari daftar "frase teks" widget (Enhancement 4,
# `PhraseSettingsReference.dc.html` di mockup) -- sengaja dipisah area
# `SISKA::OfflineMessage` sendiri, jangan dicampur ke `SISKA::LiveChat`
# atau daftar frase nanti.
#
#   bundle exec rails runner script/create_offline_message_otp_settings.rb RAILS_ENV=production

puts '== Setting: chat_offline_otp_expiry_minutes =='
Setting.create_if_not_exists(
  title:       'Offline Message OTP Expiry (Minutes)',
  name:        'chat_offline_otp_expiry_minutes',
  area:        'SISKA::OfflineMessage',
  description: 'Masa berlaku kode OTP verifikasi email untuk fitur pesan offline (Enhancement 1), dalam menit. Kode kedaluwarsa otomatis setelah durasi ini -- visitor wajib klik "Kirim ulang" untuk kode baru.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat_offline_otp_expiry_minutes',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  state:       5,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts '== Setting: chat_offline_otp_resend_cooldown_seconds =='
Setting.create_if_not_exists(
  title:       'Offline Message OTP Resend Cooldown (Seconds)',
  name:        'chat_offline_otp_resend_cooldown_seconds',
  area:        'SISKA::OfflineMessage',
  description: 'Jeda minimal (detik) antara satu permintaan "Kirim ulang" kode OTP dengan permintaan berikutnya -- mencegah tombol ini dipakai untuk spam-email ke alamat orang lain.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat_offline_otp_resend_cooldown_seconds',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  state:       30,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts '== Setting: chat_offline_otp_max_attempts =='
Setting.create_if_not_exists(
  title:       'Offline Message OTP Max Attempts',
  name:        'chat_offline_otp_max_attempts',
  area:        'SISKA::OfflineMessage',
  description: 'Jumlah maksimum percobaan kode salah sebelum kode OTP yang sedang berlaku dianggap tidak valid total (visitor wajib klik "Kirim ulang" untuk kode baru, bukan terus mencoba tebak kode yang sama).',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat_offline_otp_max_attempts',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  state:       5,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)
