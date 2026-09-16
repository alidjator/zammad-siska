# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Runs periodically via Scheduler (see docs/DESIGN_FEEDBACK_RATING.md).
#
# 1. Resets the survey state of reopened tickets so they get surveyed again,
#    unless the ticket was already rated and its Group disallows re-rating
#    on reopen (Group#csat_allow_rerating_on_reopen).
# 2. Generates a CSAT feedback token + link for newly-closed tickets that
#    haven't been surveyed yet, and records when the survey was "sent"
#    (actual delivery is handled separately by Trigger for Email/Telegram,
#    and by a dedicated sender for WhatsApp).
#
# Only considers tickets closed at or after Setting `csat_feature_launched_at`,
# to avoid mass-surveying the historical ticket backlog on first launch.
class Service::Csat::PrepareFeedbackSurveys
  def self.run
    new.run
  end

  def run
    reset_surveys_for_reopened_tickets
    send_surveys_for_newly_closed_tickets
  end

  private

  def reset_surveys_for_reopened_tickets
    Ticket.where.not(state_id: closed_state_ids)
          .where.not(csat_email_sent_at: nil)
          .find_each do |ticket|
      next if !reset_allowed?(ticket)

      ticket.update_columns(csat_email_sent_at: nil, csat_feedback_link: nil) # rubocop:disable Rails/SkipsModelValidations
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
        user_id:     ticket.customer_id,
        expires_at:  Setting.get('csat_feedback_expiry_days').to_i.days.from_now,
        preferences: { ticket_id: ticket.id },
      )

      ticket.update_columns( # rubocop:disable Rails/SkipsModelValidations
        csat_feedback_link: feedback_url(ticket, token),
        csat_email_sent_at: Time.zone.now,
      )
    end
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
