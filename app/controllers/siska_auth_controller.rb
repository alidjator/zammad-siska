# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Redesign login/register SISKA -- Tahap 1 (OTP register) & Tahap 3
# (OTP lupa password). Endpoint
# publik (visitor belum login), CSRF tetap berlaku (ajax Zammad
# mengirim X-CSRF-Token). Semua respons berstatus 200 dgn `message`
# 'ok'/'failed' + `state` -- sama dgn pola `users#email_verify_send`,
# dan TIDAK membocorkan email mana yg terdaftar (lihat Siska::AuthOtp).
class SiskaAuthController < ApplicationController

  # POST /api/v1/siska_auth/signup_otp/verify  { email, code }
  # Kode benar -> akun terverifikasi (sama dgn klik link verifikasi) &
  # langsung login.
  def signup_otp_verify
    Service::CheckFeatureEnabled.execute(name: 'user_create_account')

    otp    = Siska::AuthOtp.new(purpose: 'signup', email: params[:email])
    result = otp.verify(params[:code])

    if result[:state] != 'verified'
      render json: { message: 'failed' }.merge(result.slice(:state, :attempts_left)), status: :ok
      return
    end

    user = result[:user]
    user.update!(verified: true)
    Token.where(action: 'Signup', user_id: user.id).destroy_all
    current_user_set(user)

    render json: { message: 'ok', user_email: user.email }, status: :ok
  rescue Service::CheckFeatureEnabled::FeatureDisabledError => e
    raise Exceptions::UnprocessableContent, e.message
  end

  # POST /api/v1/siska_auth/signup_otp/resend  { email }
  # Kirim ulang email verifikasi (kode baru + link cadangan).
  def signup_otp_resend
    Service::CheckFeatureEnabled.execute(name: 'user_create_account')

    otp     = Siska::AuthOtp.new(purpose: 'signup', email: params[:email])
    blocked = otp.send_blocked
    if blocked
      render json: { message: 'failed' }.merge(blocked), status: :ok
      return
    end

    otp.register_request!
    begin
      Service::User::Deprecated::Signup.execute(user_data: { email: otp.email }, resend: true)
    rescue Service::User::Signup::TokenGenerationError
      Rails.logger.error "SISKA auth OTP: gagal membuat token signup utk kirim ulang (#{otp.email.inspect})"
    end

    render json: { message: 'ok' }.merge(otp_rules), status: :ok
  rescue Service::CheckFeatureEnabled::FeatureDisabledError => e
    raise Exceptions::UnprocessableContent, e.message
  end

  # ------------------------------------------------------------------
  # Tahap 3 -- lupa password dgn OTP: username/email -> kode 6 digit ->
  # password baru -> langsung masuk. Link reset di email tetap berlaku
  # (users#password_reset_verify tidak diubah).
  # ------------------------------------------------------------------

  # POST /api/v1/siska_auth/password_reset_otp/request  { username }
  # Juga dipakai utk kirim ulang. Respons SERAGAM utk akun ada/tidak.
  def password_reset_otp_request
    Service::CheckFeatureEnabled.execute(name: 'user_lost_password')
    raise Exceptions::UnprocessableContent, 'username param needed!' if params[:username].blank?

    otp     = Siska::AuthOtp.new(purpose: 'password_reset', email: params[:username])
    blocked = otp.send_blocked
    if blocked
      render json: { message: 'failed' }.merge(blocked), status: :ok
      return
    end

    otp.register_request!
    Service::User::PasswordReset::Deprecated::Send.execute(username: otp.email)

    render json: { message: 'ok' }.merge(otp_rules), status: :ok
  rescue Service::CheckFeatureEnabled::FeatureDisabledError => e
    raise Exceptions::UnprocessableContent, e.message
  end

  # POST /api/v1/siska_auth/password_reset_otp/verify  { username, code }
  # Kode benar -> token reset baru (sekali pakai, link di email ikut
  # tidak berlaku) utk langkah password baru. Belum login di sini.
  def password_reset_otp_verify
    Service::CheckFeatureEnabled.execute(name: 'user_lost_password')

    otp    = Siska::AuthOtp.new(purpose: 'password_reset', email: params[:username])
    result = otp.verify(params[:code])

    if result[:state] != 'verified'
      render json: { message: 'failed' }.merge(result.slice(:state, :attempts_left)), status: :ok
      return
    end

    user = result[:user]
    Token.where(action: 'PasswordReset', user_id: user.id).destroy_all
    token = Token.create!(action: 'PasswordReset', user_id: user.id, persistent: false)

    render json: { message: 'ok', reset_token: token.token }, status: :ok
  rescue Service::CheckFeatureEnabled::FeatureDisabledError => e
    raise Exceptions::UnprocessableContent, e.message
  end

  # POST /api/v1/siska_auth/password_reset_otp/complete  { reset_token, password }
  # Password disimpan lewat service bawaan (kebijakan password, email
  # "password diubah"), lalu langsung login -- KECUALI user ber-2FA
  # (atau wajib 2FA): tidak di-login-kan otomatis supaya 2FA tidak
  # terlewati, frontend mengarahkan ke halaman login.
  def password_reset_otp_complete
    raise Exceptions::UnprocessableContent, 'reset_token param needed!' if params[:reset_token].blank?

    begin
      user = Service::User::PasswordReset::Update.execute(token: params[:reset_token], password: params[:password])
    rescue Service::User::PasswordReset::Update::InvalidTokenError, Service::User::PasswordReset::Update::EmailError
      render json: { message: 'failed', state: 'invalid_token' }, status: :ok
      return
    rescue PasswordPolicy::Error => e
      render json: { message: 'failed', state: 'password_policy', notice: e.metadata }, status: :ok
      return
    end

    if user.two_factor_configured? || user.two_factor_setup_required?
      render json: { message: 'ok', logged_in: false }, status: :ok
      return
    end

    current_user_set(user)
    render json: { message: 'ok', logged_in: true }, status: :ok
  rescue Service::CheckFeatureEnabled::FeatureDisabledError => e
    raise Exceptions::UnprocessableContent, e.message
  end

  # GET /api/v1/siska_auth/password_policy -- aturan password utk
  # checklist form register (setting-nya `frontend: false`, jadi tidak
  # ada di App.Config sebelum login). Hanya aturan, tanpa data sensitif.
  def password_policy
    render json: {
      min_size:              Setting.get('password_min_size').to_i,
      need_digit:            ActiveModel::Type::Boolean.new.cast(Setting.get('password_need_digit')),
      need_lower_upper:      ActiveModel::Type::Boolean.new.cast(Setting.get('password_min_2_lower_2_upper_characters')),
      need_special_character: ActiveModel::Type::Boolean.new.cast(Setting.get('password_need_special_character')),
    }, status: :ok
  end

  private

  def otp_rules
    {
      expires_in_minutes: Siska::AuthOtp.expiry_minutes,
      cooldown_seconds:   Siska::AuthOtp.cooldown_seconds,
      max_attempts:       Siska::AuthOtp.max_attempts,
    }
  end
end
