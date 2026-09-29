# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# FRT target per group (default) or per channel for the "KPI Tim" /
# "KPI Saya" dashboards -- see docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 20.
#
#   - Group attribute frt_target_minutes (Admin > Groups > edit): one number,
#     the "Baik" boundary for that group's customer tickets. Blank = global
#     target (good_max of Setting team_kpi_frt_thresholds).
#   - Setting team_kpi_frt_target_basis: 'group' (default) | 'channel'.
#   - Setting team_kpi_frt_target_by_channel: one number per channel, used
#     when the basis is 'channel'. Blank = global target.
#   - Setting team_kpi_frt_time_basis (Section 22): 'calendar' (default,
#     = Reporting FRT) | 'business' (first_response_in_min, kalender SLA).
#   - Setting team_kpi_frt_target_by_help_topic (Section 22.5): one target
#     per SLA (= per help topic), the default basis.
#   - Setting team_kpi_frt_target_chat_minutes (Section 22): target live
#     chat in plain minutes since the chat started, default 4 (= widget
#     waitingListTimeout); always used
#     for chat tickets.
#   - Card status = share of tickets answered within their own target,
#     banded with the EXISTING Rasio Escalated thresholds
#     (team_kpi_escalated_thresholds) applied to the share that was late.
#
#   bundle exec rails runner script/create_team_kpi_frt_target.rb RAILS_ENV=production
#
# Safe to re-run (ObjectManager::Attribute.add without force, and
# Setting.create_if_not_exists are no-ops on existing records).

UserInfo.current_user_id = 1

puts '== Group: frt_target_minutes =='
ObjectManager::Attribute.add(
  object:      'Group',
  name:        'frt_target_minutes',
  display:     'Target FRT (menit)',
  data_type:   'integer',
  data_option: {
    default: '',
    min:     1,
    max:     100_000,
    null:    true,
    note:    'Target waktu respons pertama untuk tiket customer di grup ini (batas "Baik" di dashboard KPI Tim / KPI Saya). Kosong = target global (Admin > SISKA > KPI Tim). Hanya dipakai kalau "Dasar target FRT" = Per grup.',
  },
  active:      true,
  screens:     {
    create: { '-all-' => { shown: true, null: true } },
    edit:   { '-all-' => { shown: true, null: true } },
  },
  position:    610,
)

ObjectManager::Attribute.migration_execute
Group.reset_column_information

puts '== Setting: team_kpi_frt_target_basis =='
# Default per help topic = dimensi SLA SISKA (Section 22.5). Opsinya ditulis
# ulang tiap run supaya Setting lama (group/channel saja) ikut diperbarui.
basis_options = {
  form: [
    {
      display: '',
      null:    false,
      name:    'team_kpi_frt_target_basis',
      tag:     'select',
      options: {
        'help_topic' => 'Per help topic (default, sama dengan SLA)',
        'group'      => 'Per grup (field Target FRT di Admin > Groups)',
        'channel'    => 'Per kanal',
      },
    },
  ],
}
Setting.create_if_not_exists(
  title:       'KPI Tim: Dasar target FRT',
  name:        'team_kpi_frt_target_basis',
  area:        'TeamKpi::Base',
  description: 'Target FRT tiap tiket diambil dari help topic-nya (Setting "Target FRT per help topic", satu isian per SLA -- dimensi yang sama dengan SLA), dari grupnya (field "Target FRT (menit)" di Admin > Groups), atau dari kanalnya. Isian kosong memakai target global = "Good max" di "KPI Tim FRT thresholds".',
  options:     basis_options,
  state:       'help_topic',
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)
Setting.find_by(name: 'team_kpi_frt_target_basis').update!(options: basis_options)

puts '== Setting: team_kpi_frt_target_by_help_topic =='
# Satu isian per SLA (kunci sla_<id>, label = nama SLA); help topic diambil
# dari kondisi SLA (Scope.frt_target_by_help_topic). Dibuat ulang tiap run
# supaya SLA baru ikut muncul; nilai yang sudah diisi tetap.
topic_options = {
  form: Sla.order(:name).map do |sla|
    { display: sla.name, null: true, name: "sla_#{sla.id}", tag: 'input', type: 'number' }
  end,
}
Setting.create_if_not_exists(
  title:       'KPI Tim: Target FRT per help topic (menit)',
  name:        'team_kpi_frt_target_by_help_topic',
  area:        'TeamKpi::Base',
  description: 'Dipakai kalau "Dasar target FRT" = Per help topic (default). Satu isian per SLA; berlaku untuk help topic di kondisi SLA itu. Menit, dalam "Dasar waktu FRT". Kosong = target global. Script create_team_kpi_frt_target.rb dijalankan ulang kalau ada SLA baru.',
  options:     topic_options,
  state:       {},
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)
Setting.find_by(name: 'team_kpi_frt_target_by_help_topic').update!(options: topic_options)

puts '== Setting: team_kpi_frt_target_by_channel =='
# keys = Ticket::Article::Type names without spaces; see
# Service::Dashboard::TeamKpi::Scope::FRT_TARGET_CHANNELS
Setting.create_if_not_exists(
  title:       'KPI Tim: Target FRT per kanal (menit)',
  name:        'team_kpi_frt_target_by_channel',
  area:        'TeamKpi::Base',
  description: 'Dipakai kalau "Dasar target FRT" = Per kanal. Satu angka per kanal pembuat tiket, dalam menit. Kosong = target global.',
  options:     {
    form: [
      { display: 'Email',    null: true, name: 'email',    tag: 'input', type: 'number' },
      { display: 'Web',      null: true, name: 'web',      tag: 'input', type: 'number' },
      { display: 'Phone',    null: true, name: 'phone',    tag: 'input', type: 'number' },
      { display: 'Chat',     null: true, name: 'chat',     tag: 'input', type: 'number' },
      { display: 'SMS',      null: true, name: 'sms',      tag: 'input', type: 'number' },
      { display: 'Telegram', null: true, name: 'telegram', tag: 'input', type: 'number' },
      { display: 'WhatsApp', null: true, name: 'whatsapp', tag: 'input', type: 'number' },
    ],
  },
  state:       {},
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

# (tidak ada Setting ambang % sendiri: status mengikuti
# team_kpi_escalated_thresholds atas % terlambat, Section 22.4)
Setting.find_by(name: 'team_kpi_frt_target_met_thresholds')&.destroy

puts '== Setting: team_kpi_frt_time_basis (Section 22) =='
Setting.create_if_not_exists(
  title:       'KPI Tim: Dasar waktu FRT',
  name:        'team_kpi_frt_time_basis',
  area:        'TeamKpi::Base',
  description: 'Jam kalender (default) = sama dengan FRT di menu Reporting. Jam kerja = menit kerja menurut kalender SLA tiket (Admin > Calendars; sekarang Sen-Jum 08.00-17.00 + libur), dari first_response_in_min Zammad. Grup yang bekerja di luar jam kantor cukup diberi SLA dengan kalender sendiri. Live chat dan tiket tanpa SLA tetap memakai jam kalender. Jam kalender = 24 jam x 7 hari. Target FRT (grup/kanal) dibaca dalam dasar waktu yang sama.',
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'team_kpi_frt_time_basis',
        tag:     'select',
        options: {
          'calendar' => 'Jam kalender (24x7, default -- sama dengan Reporting FRT)',
          'business' => 'Jam kerja (kalender SLA)',
        },
      },
    ],
  },
  # default kalender = rumus FRT di menu Reporting (Report::TicketFirstResponseTime), Section 22.5
  state:       'calendar',
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts '== Setting: team_kpi_frt_target_chat_minutes (Section 22) =='
Setting.create_if_not_exists(
  title:       'KPI Tim: Target FRT live chat (menit, jam biasa)',
  name:        'team_kpi_frt_target_chat_minutes',
  area:        'TeamKpi::Base',
  description: 'Target respons pertama untuk tiket live chat, dalam menit jam biasa sejak customer memulai chat (waktu antrian ikut). Selalu dipakai untuk chat, apa pun "Dasar target FRT" (grup/kanal). Default 4 = batas antrian widget chat (waitingListTimeout). Boleh desimal. Kosong/0 = chat ikut target grup/kanal.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'team_kpi_frt_target_chat_minutes',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  # = waitingListTimeout widget chat (4 menit, public/assets/chat/chat-no-jquery.coffee):
  # batas tunggu yang sudah berlaku di SISKA sebelum customer diberi pesan timeout
  state:       4,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts "Group.frt_target_minutes: #{Group.column_names.include?('frt_target_minutes')}"
puts "topik: #{Setting.get('team_kpi_frt_target_by_help_topic').inspect}"
puts "chat: #{Setting.get('team_kpi_frt_target_chat_minutes').inspect}; waktu: #{Setting.get('team_kpi_frt_time_basis')}; basis: #{Setting.get('team_kpi_frt_target_basis')}; channel: #{Setting.get('team_kpi_frt_target_by_channel').inspect}"
