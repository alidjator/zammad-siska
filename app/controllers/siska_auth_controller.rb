# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Redesign login/register SISKA -- Tahap 1 (OTP register). Endpoint
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
