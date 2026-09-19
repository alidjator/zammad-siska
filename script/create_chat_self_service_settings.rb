# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 6 -- Live Chat Follow-Up Tiket untuk Semua User Login. See
# docs/DESIGN_CHAT_SELF_SERVICE.md Section 5.6/5.7.
#
#   bundle exec rails runner script/create_chat_self_service_settings.rb RAILS_ENV=production

default_chat = Chat.find_by(name: 'Customer Service') || Chat.first

puts '== Setting: chat_self_service_enabled =='
Setting.create_if_not_exists(
  title:       'Live Chat Self-Service Enabled',
  name:        'chat_self_service_enabled',
  area:        'SISKA::LiveChat',
  description: 'Saklar utama fitur live chat follow-up tiket untuk semua user login (docs/DESIGN_CHAT_SELF_SERVICE.md). KOSONG/nonaktif (default) sampai pengujian selesai -- begitu diaktifkan, berlaku untuk SEMUA user login yang punya minimal satu tiket terbuka, tidak dibatasi role tertentu. Mematikan Setting ini TIDAK memengaruhi widget live chat publik (visitor anonim, Fase 5 Item 5/6) sama sekali -- jalur keduanya sengaja dipisahkan di kode.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat_self_service_enabled',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
        translate: true,
      },
    ],
  },
  state:       false,
  preferences: { permission: ['admin.system'] },
  frontend:    true,
)

puts '== Setting: chat_self_service_chat_id =='
Setting.create_if_not_exists(
  title:       'Live Chat Self-Service Default Topic',
  name:        'chat_self_service_chat_id',
  area:        'SISKA::LiveChat',
  description: 'Topik chat default (fallback) untuk follow-up tiket lewat live chat self-service (docs/DESIGN_CHAT_SELF_SERVICE.md Section 5.6/5.7). Dipakai kalau tiket yang di-follow-up tidak punya topik chat khusus untuk Group-nya, atau routing per-Group dimatikan/topik tujuannya belum ada agent aktif.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat_self_service_chat_id',
        tag:     'select',
        multiple: false,
        options: Chat.all.each_with_object({}) { |c, h| h[c.id] = c.name },
      },
    ],
  },
  state:       default_chat&.id,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts '== Setting: chat_self_service_route_by_ticket_group =='
Setting.create_if_not_exists(
  title:       'Live Chat Self-Service Route by Ticket Group',
  name:        'chat_self_service_route_by_ticket_group',
  area:        'SISKA::LiveChat',
  description: 'Kalau NYALA (default), sistem akan mencoba mengarahkan follow-up chat ke topik chat yang preferensi "ticket_group_id"-nya cocok dengan Group pemilik tiket (dikonfigurasi lewat Admin > Channels > Chat, field yang SUDAH ADA sejak Fase 5) -- fallback otomatis ke topik default di atas kalau tidak ada topik yang cocok, atau topiknya ada tapi belum ada agent yang mengaktifkannya. Kalau MATI, semua follow-up chat langsung pakai topik default di atas, apa pun Group tiketnya.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat_self_service_route_by_ticket_group',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
        translate: true,
      },
    ],
  },
  state:       true,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts 'Done.'
