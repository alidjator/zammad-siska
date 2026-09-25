# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Riwayat chat di WIDGET customer (mockup "Riwayat chat di widget -- email
# sama + verifikasi OTP"). Keputusan user: riwayat dari email yang sama,
# perangkat apa pun -- karena customer widget anonim & email hanya DIKETIK
# sendiri, riwayat baru dibuka setelah email itu diverifikasi lewat OTP
# (chat_customer_history_otp_request / _verify). Tanpa verifikasi yang
# dikembalikan hanya `state: locked`.

class Sessions::Event::ChatCustomerHistory < Sessions::Event::ChatBase

=begin

a customer (widget) loads one page of earlier chats from the same email

payload

  {
    event: 'chat_customer_history',
    data: {
      session_id: '...',
      before_id:  123, # optional
    },
  }

return is sent as message back to peer

=end

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session
    return if Array(chat_session.preferences[:participants]).exclude?(@client_id)

    data = { session_id: chat_session.session_id, before_id: @payload['data']['before_id'] }
    if chat_session.email.blank?
      return { event: 'chat_customer_history', data: data.merge(state: 'unavailable') }
    end
    if chat_session.otp_verified_at.blank?
      return { event: 'chat_customer_history', data: data.merge(state: 'locked', email: chat_session.email) }
    end

    page = chat_session.history_page(before_id: @payload['data']['before_id'], audience: :customer)
    { event: 'chat_customer_history', data: data.merge(page).merge(state: 'ok') }
  end

end
