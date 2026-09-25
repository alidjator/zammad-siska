# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Live chat SISKA -- agent otomatis offline bila tidak ada aktivitas di
# aplikasi & tidak ada chat terbuka (lihat `startAwayWatch` di
# app/assets/javascripts/app/controllers/chat.coffee). Nilai dalam menit,
# 0 = nonaktif. Diatur di Admin > Channels > Chat (area Chat::Extended).
#
#   bundle exec rails runner script/create_chat_agent_away_setting.rb RAILS_ENV=production

Setting.create_if_not_exists(
  title:       'Agent away timeout',
  name:        'chat_agent_away_timeout',
  area:        'Chat::Extended',
  description: 'Minutes without activity in the app (mouse, keyboard, touch) and without open chats until the agent is set offline automatically. 0 disables it.',
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'chat_agent_away_timeout',
        tag:     'input',
      },
    ],
  },
  state:       '10',
  preferences: {
    permission: ['admin.channel_chat'],
  },
  frontend:    true
)

puts 'Done.'
