# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Registers the CSAT scheduler job (see app/services/service/csat/prepare_feedback_surveys.rb).
#
#   bundle exec rails runner script/register_csat_scheduler.rb RAILS_ENV=production
#
# Created INACTIVE on purpose: activate only once the full pipeline is in
# place (Trigger for Email/Telegram, WhatsApp sender, FeedbackController),
# otherwise csat_feedback_link/csat_email_sent_at get populated on real
# tickets with nothing actually delivering the survey yet.
#
#   Scheduler.find_by(method: 'Service::Csat::PrepareFeedbackSurveys.run').update!(active: true)

Scheduler.create_if_not_exists(
  name:          'CSAT: prepare feedback surveys',
  method:        'Service::Csat::PrepareFeedbackSurveys.run',
  period:        15.minutes,
  prio:          2,
  active:        false,
  updated_by_id: 1,
  created_by_id: 1,
)

puts 'Done.'
