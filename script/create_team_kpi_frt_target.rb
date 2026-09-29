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
#   - Setting team_kpi_frt_time_basis (Section 22): 'business' (default,
#     first_response_in_min = menit kerja kalender SLA) | 'calendar'.
#   - Setting team_kpi_frt_target_met_thresholds: the card status is the
#     share of tickets answered within their own target (each ticket is
#     judged by its group's / channel's target), banded like CSAT (higher =
#     better).
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
Setting.create_if_not_exists(
  title:       'KPI Tim: Dasar target FRT',
  name:        'team_kpi_frt_target_basis',
  area:        'TeamKpi::Base',
  description: 'Target FRT tiap tiket diambil dari grupnya (field "Target FRT (menit)" di Admin > Groups) atau dari kanal tiketnya (Setting "Target FRT per kanal"). Isian kosong memakai target global = batas "Good max" di "KPI Tim FRT thresholds".',
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'team_kpi_frt_target_basis',
        tag:     'select',
        options: {
          'group'   => 'Per grup (default)',
          'channel' => 'Per kanal',
        },
      },
    ],
  },
  state:       'group',
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

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

puts '== Setting: team_kpi_frt_target_met_thresholds =='
Setting.create_if_not_exists(
  title:       'KPI Tim: Ambang % tiket sesuai target FRT',
  name:        'team_kpi_frt_target_met_thresholds',
  area:        'TeamKpi::Base',
  description: 'Status kartu FRT dari persen tiket yang direspons dalam target grup/kanalnya masing-masing. Minimal persen untuk tiap status (makin tinggi makin baik).',
  options:     {
    form: [
      { display: 'Supergood min (%)', null: true, name: 'supergood_min', tag: 'input', type: 'number' },
      { display: 'Good min (%)',      null: true, name: 'good_min',      tag: 'input', type: 'number' },
      { display: 'Ok min (%)',        null: true, name: 'ok_min',        tag: 'input', type: 'number' },
      { display: 'Bad min (%)',       null: true, name: 'bad_min',       tag: 'input', type: 'number' },
    ],
  },
  state:       { 'supergood_min' => 90, 'good_min' => 80, 'ok_min' => 70, 'bad_min' => 50 },
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts '== Setting: team_kpi_frt_time_basis (Section 22) =='
Setting.create_if_not_exists(
  title:       'KPI Tim: Dasar waktu FRT',
  name:        'team_kpi_frt_time_basis',
  area:        'TeamKpi::Base',
  description: 'Jam kerja = menit kerja menurut kalender SLA tiket (Admin > Calendars; sekarang Sen-Jum 08.00-17.00 + libur), dari first_response_in_min Zammad. Grup yang bekerja di luar jam kantor cukup diberi SLA dengan kalender sendiri. Live chat dan tiket tanpa SLA tetap memakai jam kalender. Jam kalender = 24 jam x 7 hari. Target FRT (grup/kanal) dibaca dalam dasar waktu yang sama.',
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'team_kpi_frt_time_basis',
        tag:     'select',
        options: {
          'business' => 'Jam kerja (default)',
          'calendar' => 'Jam kalender (24x7)',
        },
      },
    ],
  },
  state:       'business',
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts "Group.frt_target_minutes: #{Group.column_names.include?('frt_target_minutes')}"
puts "waktu: #{Setting.get('team_kpi_frt_time_basis')}; basis: #{Setting.get('team_kpi_frt_target_basis')}; channel: #{Setting.get('team_kpi_frt_target_by_channel').inspect}; met: #{Setting.get('team_kpi_frt_target_met_thresholds').inspect}"
