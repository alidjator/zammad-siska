# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Riwayat chat di widget: kirim kode OTP ke email sesi ini (lihat
# chat_customer_history.rb). Memakai mekanisme OTP pesan offline yang sama
# (Chat::Session#generate_and_send_otp!, Setting chat_offline_otp_*).

class Sessions::Event::ChatCustomerHistoryOtpRequest < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session
    return if Array(chat_session.preferences[:participants]).exclude?(@client_id)

    data = { session_id: chat_session.session_id }
    return { event: 'chat_customer_history_otp_request', data: data.merge(state: 'failed') } if chat_session.email.blank?
    return { event: 'chat_customer_history_otp_request', data: data.merge(state: 'verified') } if chat_session.otp_verified_at.present?

    cooldown_seconds = Setting.get('chat_offline_otp_resend_cooldown_seconds').to_i
    if chat_session.otp_code_sent_at.present? && chat_session.otp_code_sent_at > cooldown_seconds.seconds.ago
      wait_seconds = (chat_session.otp_code_sent_at + cooldown_seconds.seconds - Time.zone.now).ceil
      return {
        event: 'chat_customer_history_otp_request',
        data:  data.merge(state: 'cooldown', email: chat_session.email, wait_seconds: [wait_seconds, 0].max),
      }
    end

    chat_session.generate_and_send_otp!
    { event: 'chat_customer_history_otp_request', data: data.merge(state: 'ok', email: chat_session.email) }
  end

end
