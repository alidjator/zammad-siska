# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Live chat SISKA -- chat yang agent-nya terputus (tutup browser, laptop
# sleep, internet putus) lebih dari 2 menit diubah jadi tiket & customer
# diberi tahu. Lihat `Chat.handover_disconnected_agent_sessions` dan
# `Chat::Session#handover_to_ticket!`.
#
#   bundle exec rails runner script/create_chat_handover_scheduler.rb RAILS_ENV=production

Scheduler.create_if_not_exists(
  name:          'Live Chat: alihkan chat agent terputus ke tiket',
  method:        'Chat.handover_disconnected_agent_sessions',
  period:        60,
  prio:          2,
  active:        true,
  created_by_id: 1,
  updated_by_id: 1,
)

puts 'Done.'
