# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Trigger that sends the CSAT survey email once Service::Csat::PrepareFeedbackSurveys
# populates ticket.csat_feedback_link (see docs/DESIGN_FEEDBACK_RATING.md).
#
# execution_condition_mode: 'selective' is what makes this fire only on the
# transaction where csat_feedback_link actually changes (Trigger#condition_changes_required?),
# not on every subsequent unrelated update to an already-surveyed ticket.
#
#   bundle exec rails runner script/create_csat_email_trigger.rb RAILS_ENV=production

Trigger.create_if_not_exists(
  name:                     'CSAT: send feedback survey email',
  condition:                {
    'ticket.csat_feedback_link' => {
      'operator' => 'contains',
      'value'    => '/feedback/',
    },
  },
  perform:                  {
    'notification.email' => {
      'recipient' => 'ticket_customer',
      'subject'   => 'Bagaimana pengalaman Anda dengan layanan kami? (##{ticket.number})', # rubocop:disable Lint/InterpolationCheck
      'body'      => 'Terima kasih telah menghubungi kami terkait tiket <b>#{ticket.number}</b>.<br/><br/>' \
                      'Mohon berikan rating kepuasan Anda dengan mengklik link berikut:<br/>' \
                      '<a href="#{ticket.csat_feedback_link}">#{ticket.csat_feedback_link}</a><br/><br/>' \
                      'Terima kasih,<br/>#{config.product_name}', # rubocop:disable Lint/InterpolationCheck
      'internal'  => false,
    },
  },
  activator:                'action',
  execution_condition_mode: 'selective',
  active:                   true,
  created_by_id:            1,
  updated_by_id:            1,
)

puts 'Done.'
