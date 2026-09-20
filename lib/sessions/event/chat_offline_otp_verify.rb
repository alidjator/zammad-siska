# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Enhancement 1 -- Tahap 3. Dipicu saat visitor memasukkan 6 digit kode
# di `OfflineOtp.dc.html`.
#
# payload
#
#   {
#     event: 'chat_offline_otp_verify',
#     data: {
#       session_id: 'sesi offline yang sedang diverifikasi',
#       code: '482913',
#     },
#   }
#
# return is sent as message back to peer
class Sessions::Event::ChatOfflineOtpVerify < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session

    if chat_session.state != 'offline_pending'
      return {
        event: 'chat_offline_otp_verify',
        data:  { state: 'failed', message: __('This session is no longer valid.') },
      }
    end

    result = chat_session.verify_otp(@payload['data']['code'])

    case result
    when :verified
      {
        event: 'chat_offline_otp_verify',
        data:  { state: 'ok', session_id: chat_session.session_id },
      }
    when :expired
      {
        event: 'chat_offline_otp_verify',
        data:  { state: 'expired', message: __('This code has expired. Please request a new one.') },
      }
    when :too_many_attempts
      {
        event: 'chat_offline_otp_verify',
        data:  { state: 'too_many_attempts', message: __('Too many incorrect attempts. Please request a new code.') },
      }
    else
      {
        event: 'chat_offline_otp_verify',
        data:  { state: 'incorrect', message: __('Incorrect code. Please try again.') },
      }
    end
  end

end
