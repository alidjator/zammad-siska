# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Redesign login/register SISKA -- Tahap 1 (OTP register) & Tahap 3
# (OTP lupa password). Setting fungsional OTP halaman auth, SENGAJA
# terpisah dari `chat_offline_otp_*` (live chat) supaya admin bisa
# mengatur masing-masing. Nilai awal = aturan OTP widget + batas kirim
# per jendela waktu (lihat docs/INVENTORY_LOGIN_REGISTER.md §6).
#
#   bundle exec rails runner script/create_auth_otp_settings.rb RAILS_ENV=production

def upsert_auth_otp_setting(name, title, description, value)
  if Setting.find_by(name: name)
    puts "  (sudah ada, dilewati) #{name}"
    return
  end

  Setting.create!(
    title:       title,
    name:        name,
    area:        'SISKA::AuthOtp',
    description: description,
    options:     { form: [{ display: '', null: false, name: name, tag: 'input', type: 'number' }] },
    state:       value,
    preferences: { permission: ['admin.security'] },
    frontend:    false,
  )
  puts "  dibuat: #{name} = #{value}"
end

puts '== OTP halaman auth (register & lupa password) =='
upsert_auth_otp_setting('auth_otp_expiry_minutes', 'Auth OTP Expiry (Minutes)',
                        'Masa berlaku kode OTP register / lupa password, dalam menit.', 5)
upsert_auth_otp_setting('auth_otp_max_attempts', 'Auth OTP Max Attempts',
                        'Jumlah maksimal salah memasukkan kode sebelum kode terkunci & harus minta kode baru.', 5)
upsert_auth_otp_setting('auth_otp_resend_cooldown_seconds', 'Auth OTP Resend Cooldown (Seconds)',
                        'Jeda minimal (detik) antar permintaan "Kirim ulang kode".', 30)
upsert_auth_otp_setting('auth_otp_max_sends', 'Auth OTP Max Sends per Window',
                        'Jumlah maksimal kode yang boleh dikirim ke satu email dalam satu jendela waktu (lihat auth_otp_send_window_minutes).', 5)
upsert_auth_otp_setting('auth_otp_send_window_minutes', 'Auth OTP Send Window (Minutes)',
                        'Panjang jendela waktu (menit) untuk batas auth_otp_max_sends.', 15)
puts 'Done.'
