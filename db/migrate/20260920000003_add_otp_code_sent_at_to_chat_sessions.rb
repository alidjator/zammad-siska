# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Enhancement 1 -- Tahap 3. Kolom SUSULAN dari
# `20260920000002_add_otp_to_chat_sessions.rb` -- ketahuan dibutuhkan
# saat merancang event `chat_offline_otp_resend`: cooldown "kirim
# ulang" butuh tahu KAPAN PERSIS kode terakhir dikirim, BEDA dari
# `otp_expires_at` (kapan kode itu KEDALUWARSA) -- menurunkan salah
# satu dari yang lain (mis. `otp_expires_at - expiry_minutes`) rapuh
# kalau Setting durasi expiry berubah di antara kirim & cek cooldown.
# Kolom terpisah lebih jelas & tidak rapuh.
class AddOtpCodeSentAtToChatSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_sessions, :otp_code_sent_at, :datetime, null: true
  end
end
