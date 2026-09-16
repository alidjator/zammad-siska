# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Admin-editable message templates for the channels that have no native
# Trigger action (Telegram, WhatsApp) -- see docs/DESIGN_FEEDBACK_RATING.md.
# Placeholders: %{ticket_number}, %{feedback_link}.
#
#   bundle exec rails runner script/create_csat_message_settings.rb RAILS_ENV=production

DEFAULT_TEMPLATE = "Terima kasih telah menghubungi kami terkait tiket #%{ticket_number}. " \
                    "Mohon berikan rating kepuasan Anda:\n%{feedback_link}".freeze

Setting.create_if_not_exists(
  title:       'CSAT Telegram Message Template',
  name:        'csat_telegram_message_template',
  area:        'CSAT::Base',
  description: 'Message sent via Telegram after a ticket is closed, asking for a CSAT rating.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'csat_telegram_message_template',
        tag:     'textarea',
      },
    ],
  },
  state:       DEFAULT_TEMPLATE,
  preferences: { permission: ['admin.setting_system'] },
  frontend:    false,
)

Setting.create_if_not_exists(
  title:       'CSAT WhatsApp Message Template',
  name:        'csat_whatsapp_message_template',
  area:        'CSAT::Base',
  description: 'Message sent via WhatsApp after a ticket is closed, asking for a CSAT rating.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'csat_whatsapp_message_template',
        tag:     'textarea',
      },
    ],
  },
  state:       DEFAULT_TEMPLATE,
  preferences: { permission: ['admin.setting_system'] },
  frontend:    false,
)

puts 'Done.'
