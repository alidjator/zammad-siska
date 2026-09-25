# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Live chat SISKA -- pemantau koneksi tiap menit (`Chat.check_live_chat_connections`):
# * agent terputus > 2 menit -> chat diubah jadi tiket, customer diberi tahu
# * customer terputus > 2 menit (tanpa sempat kirim leave) -> sesi ditutup
# * ketersediaan chat berubah tanpa event (agent kedaluwarsa) -> push ke widget
# Aman dijalankan ulang: record lama (method handover_disconnected_agent_sessions)
# ikut diperbarui.
#
#   bundle exec rails runner script/create_chat_handover_scheduler.rb RAILS_ENV=production

scheduler = Scheduler.find_by(method: 'Chat.handover_disconnected_agent_sessions') ||
            Scheduler.find_by(method: 'Chat.check_live_chat_connections') ||
            Scheduler.new(created_by_id: 1)

scheduler.update!(
  name:          'Live Chat: pantau koneksi agent & customer',
  method:        'Chat.check_live_chat_connections',
  period:        60,
  prio:          2,
  active:        true,
  updated_by_id: 1,
)

puts 'Done.'
