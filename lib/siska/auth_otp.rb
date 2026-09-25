# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Redesign login/register SISKA -- OTP halaman auth (Tahap 1: register;
# dipakai ulang Tahap 3: lupa password). Aturan (docs/
# INVENTORY_LOGIN_REGISTER.md §6): 6 digit, berlaku
# `auth_otp_expiry_minutes`, maks. `auth_otp_max_attempts` kali salah,
# jeda kirim ulang `auth_otp_resend_cooldown_seconds`, maks.
# `auth_otp_max_sends` kode per `auth_otp_send_window_minutes`.
#
# Dua tempat simpan, SENGAJA dipisah:
# - Hash kode (SHA-256) di record `Token` milik user (action
#   `<Purpose>Otp`) -- cuma ada kalau user-nya sungguh ada.
# - Status permintaan (waktu terbit, jumlah salah, riwayat kirim) di
#   Rails.cache per email (di-hash), dicatat SERAGAM utk email terdaftar
#   MAUPUN tidak -- jadi respons verify/resend (sisa percobaan,
#   kedaluwarsa, jeda) identik & tidak membocorkan email mana yg
#   terdaftar (pola sama dgn Service::User::Signup yg selalu "sukses").
module Siska
  class AuthOtp
    PURPOSES = {
      'signup'         => 'SignupOtp',
      'password_reset' => 'PasswordResetOtp',
    }.freeze
    CACHE_TTL = 1.hour

    attr_reader :purpose, :email

    def self.expiry_minutes
      [Setting.get('auth_otp_expiry_minutes').to_i, 1].max
    end

    def self.max_attempts
      [Setting.get('auth_otp_max_attempts').to_i, 1].max
    end

    def self.cooldown_seconds
      Setting.get('auth_otp_resend_cooldown_seconds').to_i
    end

    def self.max_sends
      [Setting.get('auth_otp_max_sends').to_i, 1].max
    end

    def self.send_window
      [Setting.get('auth_otp_send_window_minutes').to_i, 1].max.minutes
    end

    def self.digest(code)
      Digest::SHA256.hexdigest(code.to_s)
    end

    def initialize(purpose:, email:)
      raise ArgumentError, "unknown purpose #{purpose}" if !PURPOSES.key?(purpose)

      @purpose = purpose
      @email   = email.to_s.strip.downcase
    end

    # Boleh kirim kode baru? -> nil kalau boleh, selain itu hash alasan
    # (`cooldown` / `rate_limited`) + `wait_seconds`.
    def send_blocked
      now   = Time.zone.now
      state = read_state
      sends = recent_sends(state, now)

      if state[:issued_at] && state[:issued_at] > self.class.cooldown_seconds.seconds.ago
        return { state: 'cooldown', wait_seconds: (state[:issued_at] + self.class.cooldown_seconds.seconds - now).ceil }
      end

      if sends.size >= self.class.max_sends
        return { state: 'rate_limited', wait_seconds: (sends.min + self.class.send_window - now).ceil }
      end

      nil
    end

    # Catat permintaan kode (SERAGAM, dipanggil pemanggil utk setiap
    # permintaan yg lolos `send_blocked`, email terdaftar atau tidak).
    def register_request!
      now   = Time.zone.now
      state = read_state
      write_state(issued_at: now, attempts: 0, sends: recent_sends(state, now) + [now])
    end

    # Buat kode baru utk user yg SUNGGUH ada & simpan hash-nya. Kode
    # lama (kalau ada) langsung tidak berlaku. -> kode (String).
    def issue_code!(user)
      code = format('%06d', SecureRandom.random_number(1_000_000))
      Token.where(action: token_action, user_id: user.id).destroy_all
      Token.create!(
        action:      token_action,
        user_id:     user.id,
        persistent:  false,
        expires_at:  self.class.expiry_minutes.minutes.from_now,
        preferences: { code_digest: self.class.digest(code) },
      )
      state = read_state
      write_state(state.merge(issued_at: Time.zone.now, attempts: 0)) if state[:issued_at].blank?
      code
    end

    # -> { state: 'verified', user: } | { state: 'incorrect',
    # attempts_left: } | { state: 'expired' } | { state: 'too_many_attempts' }
    def verify(code)
      state = read_state
      return { state: 'expired' } if state[:issued_at].blank? || state[:issued_at] < self.class.expiry_minutes.minutes.ago
      return { state: 'too_many_attempts' } if state[:attempts].to_i >= self.class.max_attempts

      user  = find_user
      token = user && Token.find_by(action: token_action, user_id: user.id)
      given = self.class.digest(code.to_s.strip)
      match = token.present? &&
              token.expires_at.present? && token.expires_at > Time.zone.now &&
              ActiveSupport::SecurityUtils.secure_compare(token.preferences[:code_digest].to_s, given)

      if !match
        attempts = state[:attempts].to_i + 1
        write_state(state.merge(attempts: attempts))
        return { state: 'too_many_attempts' } if attempts >= self.class.max_attempts

        return { state: 'incorrect', attempts_left: self.class.max_attempts - attempts }
      end

      token.destroy
      write_state(state.merge(issued_at: nil, attempts: 0))
      { state: 'verified', user: user }
    end

    private

    def token_action
      PURPOSES[purpose]
    end

    def find_user
      return if email.blank?

      ::User.find_by(email: email)
    end

    def cache_key
      "siska_auth_otp/#{purpose}/#{self.class.digest(email)}"
    end

    def read_state
      (Rails.cache.read(cache_key) || {}).symbolize_keys
    end

    def write_state(state)
      Rails.cache.write(cache_key, state, expires_in: CACHE_TTL)
    end

    def recent_sends(state, now)
      Array(state[:sends]).select { |t| t > now - self.class.send_window }
    end
  end
end
