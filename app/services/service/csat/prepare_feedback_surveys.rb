# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Runs periodically via Scheduler (see docs/DESIGN_FEEDBACK_RATING.md).
#
# 1. Resets the survey state of reopened tickets so they get surveyed again,
#    unless the ticket was already rated and its Group disallows re-rating
#    on reopen (Group#csat_allow_rerating_on_reopen).
# 2. Generates a CSAT feedback token + link for newly-closed tickets that
#    haven't been surveyed yet, and records when the survey was "sent".
#    Delivery: Email is handled by a separate Trigger (admin-editable,
#    fires off ticket.csat_feedback_link becoming present -- see
#    script/create_csat_email_trigger.rb). Telegram and WhatsApp have no
#    equivalent Trigger action in this Zammad version, so we send them
#    directly here (Telegram: create a properly-typed Article and let
#    Zammad's own CommunicateTelegramJob deliver it; WhatsApp: POST
#    straight to the gateway, since the Channel::Driver::Sms::Pkpwa
#    adapter referenced in Channel#options doesn't exist in this codebase
#    -- see docs/DESIGN_FEEDBACK_RATING.md).
#
# Only considers tickets closed at or after Setting `csat_feature_launched_at`,
# to avoid mass-surveying the historical ticket backlog on first launch.
#
# CSAT tokens are created with persistent: true (see #send_surveys_for_newly_closed_tickets
# for why), which means Token.cleanup (core Zammad) never removes them --
# it only targets persistent: false tokens. We clean up our own expired
# tokens here instead.
#
# IMPORTANT: ticket.csat_feedback_link/csat_email_sent_at updates use
# ticket.update! (not update_columns, which skips all callbacks) wrapped in
# Transaction.execute { ... } (mirrors Ticket.process_pending). Both are
# required for the Email Trigger to actually fire: after_update
# TransactionDispatcher only buffers the event (EventBuffer) -- it's not
# processed until a Transaction.execute block finishes. Confirmed by testing:
# without the Transaction.execute wrapper, csat_feedback_link was set
# correctly but the Trigger never ran.
class Service::Csat::PrepareFeedbackSurveys
  def self.run
    new.run
  end

  def run
    reset_surveys_for_reopened_tickets
    send_surveys_for_newly_closed_tickets
    cleanup_expired_tokens
  end

  private

  def cleanup_expired_tokens
    Token.where(action: 'CustomerFeedback', expires_at: ...Time.zone.now).delete_all
  end

  def reset_surveys_for_reopened_tickets
    Ticket.where.not(state_id: closed_state_ids)
          .where.not(csat_email_sent_at: nil)
          .find_each do |ticket|
      next if !reset_allowed?(ticket)

      Transaction.execute do
        ticket.update!(csat_email_sent_at: nil, csat_feedback_link: nil)
      end
    end
  end

  def reset_allowed?(ticket)
    return true if ticket.csat_score.blank?

    ticket.group.csat_allow_rerating_on_reopen != false
  end

  def send_surveys_for_newly_closed_tickets
    Ticket.where(state_id: closed_state_ids)
          .where(csat_email_sent_at: nil)
          .where(close_at: launched_at..)
          .find_each do |ticket|
      next if ticket.customer_id.blank?

      token = Token.create!(
        action:      'CustomerFeedback',
        persistent:  true, # Token#check? auto-destroys non-persistent tokens after 1 day
                           # regardless of expires_at -- we validate expires_at ourselves instead.
        user_id:     ticket.customer_id,
        expires_at:  Setting.get('csat_feedback_expiry_days').to_i.days.from_now,
        preferences: { ticket_id: ticket.id },
      )

      Transaction.execute do
        ticket.update!(
          csat_feedback_link: feedback_url(ticket, token),
          csat_email_sent_at: Time.zone.now,
        )
      end

      send_via_channel(ticket)
    end
  end

  # Email is intentionally NOT handled here -- the Trigger created by
  # script/create_csat_email_trigger.rb reacts to csat_feedback_link
  # becoming present and sends it, so admins can edit the wording without
  # touching code.
  def send_via_channel(ticket)
    channel_name = ticket.create_article_type&.name.to_s

    if channel_name.match?(/\Atelegram/i)
      send_telegram(ticket)
    elsif channel_name == 'sms'
      send_whatsapp(ticket)
    end
  end

  def send_telegram(ticket)
    return if ticket.preferences['telegram'].blank?

    Ticket::Article.create!(
      ticket_id:     ticket.id,
      type_id:       Ticket::Article::Type.find_by(name: 'telegram personal-message').id,
      sender_id:     Ticket::Article::Sender.find_by(name: 'System').id,
      internal:      false,
      content_type:  'text/plain',
      body:          render_template(Setting.get('csat_telegram_message_template'), ticket),
      updated_by_id: 1,
      created_by_id: 1,
    )
  rescue => e
    Rails.logger.error("CSAT Telegram send failed for ticket #{ticket.id}: #{e.message}")
  end

  # Safety toggle: off by default (Setting csat_whatsapp_enabled) until the
  # payload shape below -- a best-effort guess, see
  # docs/WHATSAPP_GATEWAY_REQUIREMENTS.md -- is confirmed with the team
  # that maintains this gateway. Does not affect Email/Telegram.
  def send_whatsapp(ticket)
    return if !Setting.get('csat_whatsapp_enabled')

    phone = ticket.customer&.mobile.presence || ticket.customer&.phone
    return if phone.blank?

    channel = Channel.where(area: 'Sms::Notification', active: true).detect { |c| c.options['adapter'] == 'sms/pkpwa' }
    return if channel.blank? || channel.options['gateway'].blank?

    Faraday.post(channel.options['gateway']) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        device:  channel.options['device'],
        to:      phone,
        message: render_template(Setting.get('csat_whatsapp_message_template'), ticket),
      }.to_json
    end
  rescue => e
    Rails.logger.error("CSAT WhatsApp send failed for ticket #{ticket.id}: #{e.message}")
  end

  def render_template(template, ticket)
    format(template, ticket_number: ticket.number, feedback_link: ticket.csat_feedback_link)
  end

  def closed_state_ids
    @closed_state_ids ||= Ticket::State.by_category(:closed).pluck(:id)
  end

  def launched_at
    @launched_at ||= Time.zone.parse(Setting.get('csat_feature_launched_at'))
  end

  def feedback_url(ticket, token)
    scheme = Setting.get('http_type')
    fqdn   = Setting.get('fqdn')

    "#{scheme}://#{fqdn}/feedback/#{ticket.id}?token=#{token.token}"
  end
end
