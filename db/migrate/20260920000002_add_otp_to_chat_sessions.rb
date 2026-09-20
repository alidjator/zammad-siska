# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Enhancement 1 -- Tahap 3 (Offline Message + Verifikasi OTP). Kolom
# ini dipasang di `chat_sessions` (BUKAN tabel baru) -- reuse model yg
# sama dgn chat biasa, konsisten dgn keputusan "1 offline message = 1
# tiket, aturan sama dgn chat biasa" yang sudah dibahas.
#
# `otp_code` menyimpan HASH (SHA-256), BUKAN kode OTP polos -- kalau
# baris ini bocor lewat cara apa pun (dump DB, log, dst.), kode OTP
# itu sendiri TIDAK ikut bocor.
class AddOtpToChatSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_sessions, :otp_code, :string, limit: 64, null: true
    add_column :chat_sessions, :otp_expires_at, :datetime, null: true
    add_column :chat_sessions, :otp_verified_at, :datetime, null: true
    add_column :chat_sessions, :otp_attempts, :integer, null: false, default: 0
  end
end
