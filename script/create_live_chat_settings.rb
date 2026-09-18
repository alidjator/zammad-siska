# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 5 -- Item No. 5 & 6 (Live Chat Enhancement). See
# docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.1.3/5.1.6/5.2.2a/
# 5.2.4a/5.2.5. All Settings here are `frontend: false` -- read ONLY
# backend-side (by lib/sessions/event/chat_*.rb and the new chat
# attachment upload endpoint), never by the browser client, so there's
# no need to push them into App.Config.
#
#   bundle exec rails runner script/create_live_chat_settings.rb RAILS_ENV=production

puts '== Setting: chat_auto_ticket_group_id =='
Setting.create_if_not_exists(
  title:       'Live Chat Auto-Ticket Group',
  name:        'chat_auto_ticket_group_id',
  area:        'SISKA::LiveChat',
  description: 'Group tujuan default untuk tiket yang dibuat otomatis saat agent menerima sesi Live Chat (docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.1.3). Kosong = auto-create tiket dilewati dengan aman, chat tetap berjalan normal seperti sebelum fitur ini ada. PENTING: diarahkan ke Group "QA - Internal Testing" untuk pengembangan/pengujian -- WAJIB diarahkan ulang ke Group produksi sebelum dipakai untuk chat customer asli, kalau tidak tiket customer asli akan masuk ke Group tanpa anggota.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat_auto_ticket_group_id',
        tag:     'select',
        multiple: false,
        options: Group.all.each_with_object({}) { |g, h| h[g.id] = g.name },
      },
    ],
  },
  state:       Group.find_by(name: 'QA - Internal Testing')&.id,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts '== Setting: chat_attachment_allowed_extensions =='
Setting.create_if_not_exists(
  title:       'Live Chat Attachment Allowed Extensions',
  name:        'chat_attachment_allowed_extensions',
  area:        'SISKA::LiveChat',
  description: 'Daftar ekstensi file yang diizinkan untuk attachment Live Chat, dipisah koma (docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.2.4a). Ekstensi executable/script (exe, bat, cmd, sh, ps1, js, html, php, dst) SELALU ditolak terlepas dari isi Setting ini -- denylist itu hardcode di kode, tidak bisa dilonggarkan lewat sini.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat_attachment_allowed_extensions',
        tag:     'input',
        type:    'text',
      },
    ],
  },
  state:       'jpg,jpeg,png,gif,webp,pdf,doc,docx,xls,xlsx',
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts '== Setting: chat_attachment_max_size_mb =='
Setting.create_if_not_exists(
  title:       'Live Chat Attachment Max Size (MB)',
  name:        'chat_attachment_max_size_mb',
  area:        'SISKA::LiveChat',
  description: 'Ukuran maksimum tiap file attachment Live Chat dalam MB (docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.2.2a). Dibatasi pagar mutlak 20 MB di kode, tidak bisa dilewati lewat Setting ini berapa pun angkanya.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat_attachment_max_size_mb',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  state:       5,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts '== Setting: chat_attachment_clamav_host =='
Setting.create_if_not_exists(
  title:       'Live Chat Attachment ClamAV Host',
  name:        'chat_attachment_clamav_host',
  area:        'SISKA::LiveChat',
  description: 'Host clamd untuk memindai attachment Live Chat (docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.2.5). KOSONG = pemindaian nonaktif (default) -- isi begitu ClamAV tersedia untuk mengaktifkan pemindaian tanpa perlu deploy ulang.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat_attachment_clamav_host',
        tag:     'input',
        type:    'text',
      },
    ],
  },
  state:       '',
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts '== Setting: chat_attachment_clamav_port =='
Setting.create_if_not_exists(
  title:       'Live Chat Attachment ClamAV Port',
  name:        'chat_attachment_clamav_port',
  area:        'SISKA::LiveChat',
  description: 'Port clamd untuk memindai attachment Live Chat (docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.2.5). Default 3310 (port standar clamd).',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat_attachment_clamav_port',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  state:       3310,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts 'Done.'
