# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Riwayat chat di widget: verifikasi kode OTP (lihat chat_customer_history.rb).
# Setelah terverifikasi (`otp_verified_at`), riwayat terbuka utk sesi ini.

class Sessions::Event::ChatCustomerHistoryOtpVerify < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session
    return if Array(chat_session.preferences[:participants]).exclude?(@client_id)

    data = { session_id: chat_session.session_id }
    return { event: 'chat_customer_history_otp_verify', data: data.merge(state: 'ok') } if chat_session.otp_verified_at.present?

    state = case chat_session.verify_otp(@payload['data']['code'])
            when :verified then 'ok'
            when :expired then 'expired'
            when :too_many_attempts then 'too_many_attempts'
            else 'incorrect'
            end
    { event: 'chat_customer_history_otp_verify', data: data.merge(state: state) }
  end

end
