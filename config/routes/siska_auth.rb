# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Redesign login/register SISKA -- Tahap 1 (OTP register) & Tahap 3
# (OTP lupa password).
Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/siska_auth/signup_otp/verify', to: 'siska_auth#signup_otp_verify', via: :post
  match api_path + '/siska_auth/signup_otp/resend', to: 'siska_auth#signup_otp_resend', via: :post
  match api_path + '/siska_auth/password_policy',   to: 'siska_auth#password_policy',   via: :get
  match api_path + '/siska_auth/password_reset_otp/request',  to: 'siska_auth#password_reset_otp_request',  via: :post
  match api_path + '/siska_auth/password_reset_otp/verify',   to: 'siska_auth#password_reset_otp_verify',   via: :post
  match api_path + '/siska_auth/password_reset_otp/complete', to: 'siska_auth#password_reset_otp_complete', via: :post
end
