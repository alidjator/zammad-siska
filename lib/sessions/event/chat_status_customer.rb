# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::ChatStatusCustomer < Sessions::Event::ChatBase

=begin

a customer requests the current state of a chat

payload

  {
    event: 'chat_status_agent',
    data: {
      session_id: 'the id of the current chat session',
      url: 'optional url', # will trigger a chat_session_notice to agent
    },
  }

return is sent as message back to peer

=end

  def run
    return super if super
    return if !check_chat_exists
    return if blocked_ip?
    return if blocked_country?
    return if blocked_origin?

    # check if it's a chat sessin reconnect
    session_id = nil
    if @payload['data']['session_id']
      session_id = @payload['data']['session_id']

      # update recipients of existing sessions
      chat_session = Chat::Session.find_by(session_id: session_id)
      if chat_session
        chat_session.add_recipient(@client_id, true)

        # sent url update to agent
        if @payload['data']['url']
          message = {
            event: 'chat_session_notice',
            data:  {
              session_id: chat_session.session_id,
              message:    @payload['data']['url'],
            },
          }
          chat_session.send_to_recipients(message, @client_id)
        end
      end
    end

    {
      event: 'chat_status_customer',
      data:  current_chat.customer_state(session_id).merge(logo_url: product_logo_url, phrases: widget_phrases, category_options: Chat::Session.category_options),
    }
  end

  # Enhancement 4 -- "buatkan semua frase dalam widget configurable".
  # Pola SAMA dgn `product_logo_url` di atas: widget statis lintas-
  # domain tidak bisa baca `Setting.get` langsung, jadi disisipkan di
  # payload event yg SUDAH SELALU dikirim ini. Daftar nama Setting
  # PERSIS sama dgn `script/create_widget_phrase_settings.rb` (sumber
  # kebenaran nilai default) -- kalau ada Setting yg belum dibuat,
  # `Setting.get` mengembalikan `nil`, frontend fallback ke teks
  # hardcode bawaan (lihat `@phrases['key'] || 'default'` di
  # chat.coffee/chat-no-jquery.coffee).
  PHRASE_SETTING_NAMES = %w[
    chat_phrase_home_greeting
    chat_phrase_home_subtitle
    chat_phrase_home_start_button
    chat_phrase_home_search_button
    chat_phrase_home_online_notice
    chat_phrase_offline_status
    chat_phrase_offline_notice_title
    chat_phrase_offline_notice
    chat_phrase_offline_start_button
    chat_phrase_prechat_title
    chat_phrase_prechat_subtitle
    chat_phrase_prechat_name_label
    chat_phrase_prechat_email_label
    chat_phrase_prechat_category_label
    chat_phrase_prechat_category_placeholder
    chat_phrase_prechat_submit_button
    chat_phrase_prechat_validation_error
    chat_phrase_waiting_title
    chat_phrase_waiting_subtitle
    chat_phrase_waiting_queue_position
    chat_phrase_waiting_cancel_button
    chat_phrase_waiting_timeout_message
    chat_phrase_restart_button
    chat_phrase_customer_timeout_with_agent
    chat_phrase_customer_timeout
    chat_phrase_messages_agent_status_active
    chat_phrase_messages_compose_placeholder
    chat_phrase_messages_reply_prefix
    chat_phrase_messages_welcome_greeting
    chat_phrase_otp_title
    chat_phrase_otp_subtitle_prefix
    chat_phrase_otp_incomplete_error
    chat_phrase_otp_verify_button
    chat_phrase_otp_resend_question
    chat_phrase_otp_resend_button
    chat_phrase_otp_resend_success
    chat_phrase_otp_resend_error_fallback
    chat_phrase_otp_change_email
    chat_phrase_offline_compose_verified_suffix
    chat_phrase_offline_compose_subject_label
    chat_phrase_offline_compose_subject_placeholder
    chat_phrase_offline_compose_subject_empty_error
    chat_phrase_offline_compose_message_label
    chat_phrase_offline_compose_placeholder
    chat_phrase_offline_compose_send_button
    chat_phrase_offline_compose_empty_error
    chat_phrase_offline_sent_title
    chat_phrase_offline_sent_subtitle_prefix
    chat_phrase_offline_sent_subtitle_suffix
    chat_phrase_offline_sent_button
    chat_phrase_ending_title
    chat_phrase_ending_subtitle
    chat_phrase_feedback_title
    chat_phrase_feedback_subtitle
    chat_phrase_feedback_comment_placeholder
    chat_phrase_feedback_skip_button
    chat_phrase_feedback_submit_button
    chat_phrase_feedback_score_error
    chat_phrase_feedback_submit_error_fallback
    chat_phrase_feedback_thanks_title
    chat_phrase_feedback_thanks_subtitle
    chat_phrase_help_no_results
    chat_phrase_attachment_upload_error
    chat_phrase_offline_compose_attach_button
  ].freeze

  def widget_phrases
    PHRASE_SETTING_NAMES.index_with { |name| Setting.get(name) }
  end

  # Atas permintaan user ("logo pada home mengambil dari setting logo
  # zammad") -- widget disajikan sbg file statis lintas-domain, TIDAK
  # bisa baca `Setting.get('product_logo')` langsung dari SCSS/eco
  # (compile-time, tanpa akses DB) -- disertakan di SINI (payload event
  # yg SUDAH SELALU dikirim ke widget sejak `render()`, lihat
  # chat.coffee) supaya JS bisa isi logo Home secara dinamis SETELAH
  # widget dimuat, bukan bikin event/endpoint baru. URL dibangun manual
  # dari `http_type`/`fqdn` (pola yang SAMA dipakai
  # `chat_knowledge_base_search.rb`), path & param persis preseden
  # NYATA yang sudah ada (`feedback_controller.rb`, satu-satunya
  # pemakai publik/anonim endpoint `system_assets` ini di codebase).
  # `nil` kalau belum ada logo custom diupload -- frontend fallback ke
  # ikon generik yang sudah ada, tidak dipaksa.
  def product_logo_url
    return if Setting.get('product_logo').blank?

    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/api/v1/system_assets/product_logo/#{ERB::Util.url_encode(Setting.get('product_logo'))}"
  end

  def blocked_ip?
    return false if !current_chat.blocked_ip?(remote_ip)

    send_unavailable
    true
  end

  def blocked_country?
    return false if !current_chat.blocked_country?(remote_ip)

    send_unavailable
    true
  end

  def blocked_origin?
    return false if current_chat.website_allowed?(origin)

    send_unavailable
    true
  end

  def send_unavailable
    error = {
      event: 'chat_error',
      data:  {
        state: 'chat_unavailable',
      },
    }
    Sessions.send(@client_id, error)
  end
end
