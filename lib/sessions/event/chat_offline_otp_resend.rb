# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Enhancement 1 -- Tahap 3. Dipicu tautan "Kirim ulang" di
# `OfflineOtp.dc.html`. Dibatasi cooldown
# (`chat_offline_otp_resend_cooldown_seconds`) -- TANPA ini, tombol ini
# bisa dipakai spam-kirim email ke alamat siapa pun (email tujuan
# bukan milik pemanggil, cukup tebak/masukkan sembarang alamat di form
# pra-chat).
#
# payload
#
#   {
#     event: 'chat_offline_otp_resend',
#     data: { session_id: 'sesi offline yang sedang diverifikasi' },
#   }
#
# return is sent as message back to peer
class Sessions::Event::ChatOfflineOtpResend < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session

    if chat_session.state != 'offline_pending'
      return {
        event: 'chat_offline_otp_resend',
        data:  { state: 'failed', message: __('This session is no longer valid.') },
      }
    end

    cooldown_seconds = Setting.get('chat_offline_otp_resend_cooldown_seconds').to_i
    if chat_session.otp_code_sent_at.present? && chat_session.otp_code_sent_at > cooldown_seconds.seconds.ago
      wait_seconds = (chat_session.otp_code_sent_at + cooldown_seconds.seconds - Time.zone.now).ceil
      return {
        event: 'chat_offline_otp_resend',
        data:  {
          state:        'cooldown',
          wait_seconds: [wait_seconds, 0].max,
          message:      __('Please wait a moment before requesting another code.'),
        },
      }
    end

    chat_session.generate_and_send_otp!

    {
      event: 'chat_offline_otp_resend',
      data:  { state: 'ok', session_id: chat_session.session_id },
    }
  end

end
