# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Creates the Custom Object Attributes and Settings needed for Fase 4 --
# Item No. 1 (AUX Status + Auto-distribusi Tiket). See
# docs/DESIGN_AUX_STATUS.md Section 5.1/5.2 for the full design.
#
#   bundle exec rails runner script/create_aux_status_object_attributes.rb RAILS_ENV=production
#
# Safe to re-run: create_if_not_exists / ObjectManager::Attribute.add
# (no force:) are all no-ops on records that already exist.
#
# Revision history:
# - First draft: the list of AUX status VALUES was meant to live purely
#   in the `aux_status` select attribute's own Object Manager options
#   (add/remove options there, no dedicated Setting needed), with just
#   the per-status DURATION in a separate Setting (aux_status_durations).
# - Revised per explicit user request ("settingnya bisa menambah dan
#   mengurangi aux"): the user wants status VALUES themselves add/
#   removable from a single Admin > Settings > SISKA > AUX Status screen,
#   not by going into the more technical Object Manager UI. `aux_status`
#   below is now a plain `input` (not `select`) -- its own option list is
#   no longer the source of truth for anything and would only confuse an
#   admin who edited it there expecting an effect. `aux_status_options`
#   (single JSON array Setting, replaces aux_status_durations) is now the
#   ONE place that defines which statuses exist, their labels, AND their
#   durations -- read by both the backend (Service::AuxStatus::
#   ChangeStatus) and the frontend (App.Config.get('aux_status_options'),
#   frontend: true) so adding/removing a status here takes effect
#   app-wide without a code change. See docs/DESIGN_AUX_STATUS.md
#   Section 6j.

UserInfo.current_user_id = 1

puts '== User: aux_status =='
# screens: {} on purpose -- not editable via the generic User edit/create
# form, same pattern as Ticket#escalation_started_at in Fase 3. The only
# supported way to change it is via Service::AuxStatus::ChangeStatus
# (through the dedicated API/UI in Section 5.7), which enforces the
# self-or-override permission check. Plain `input`, not `select` --
# valid values are validated against Setting aux_status_options at
# write time (Service::AuxStatus::ChangeStatus), not by this attribute's
# own (now purely legacy/unused) option list.
ObjectManager::Attribute.add(
  object:      'User',
  name:        'aux_status',
  display:     'AUX Status',
  data_type:   'input',
  data_option: {
    type:      'text',
    default:   'available',
    maxlength: 255,
    null:      false,
    note:      'Internal: current AUX status. Only changeable via the AUX Status widget/API, not this form -- valid values are defined by Setting aux_status_options, see docs/DESIGN_AUX_STATUS.md.',
  },
  active:      true,
  screens:     {},
  position:    1600,
)

puts '== User: aux_status_since =='
ObjectManager::Attribute.add(
  object:      'User',
  name:        'aux_status_since',
  display:     'AUX Status Since',
  data_type:   'datetime',
  data_option: {
    future: true,
    past:   true,
    diff:   0,
    null:   true,
    note:   'Internal: when the current aux_status started. Set by Service::AuxStatus::ChangeStatus, not editable directly.',
  },
  active:      true,
  screens:     {},
  position:    1601,
)

puts '== User: aux_status_expires_at =='
ObjectManager::Attribute.add(
  object:      'User',
  name:        'aux_status_expires_at',
  display:     'AUX Status Expires At',
  data_type:   'datetime',
  data_option: {
    future: true,
    past:   true,
    diff:   0,
    null:   true,
    note:   'Internal: when the current aux_status auto-reverts to Available. Nil for durationless statuses (Available/Offline). Polled by Service::AuxStatus::ExpireStatuses.',
  },
  active:      true,
  screens:     {},
  position:    1602,
)

puts '== Cleanup: retire Setting aux_status_durations (replaced by aux_status_options) =='
Setting.find_by(name: 'aux_status_durations')&.destroy

puts '== Setting: aux_status_options =='
# Single source of truth for which AUX statuses exist, their display
# label, and their duration (minutes; 0 or absent = never auto-expires).
# Admin adds/removes a status by editing this JSON array directly --
# no code change or redeploy needed, and no separate Object Manager
# option-list to keep in sync. frontend: true so the personal-menu
# dropdown, the freeze overlay, and the Manage > AUX Status override
# page can all read the SAME live list via
# App.Config.get('aux_status_options') instead of a hardcoded JS array
# that could silently drift out of sync with this Setting.
#
# Editable via a friendly row-based UI (Value/Label/Duration inputs +
# Add/Remove buttons) rather than raw JSON, per explicit user request
# ("saya mau penambahan pengurangan ini menggunakan input field bukan
# dengan JSON, karena semua admin belum tentu tau JSON") -- see
# app/assets/javascripts/app/controllers/_settings/
# area_aux_status_options.coffee, registered below via
# `preferences: { controller: 'SettingsAreaAuxStatusOptions' }`, the
# native per-Setting override mechanism `_settings/area.coffee` already
# uses for other custom Setting widgets (e.g. App.SettingsAreaSwitch).
#
# IMPORTANT: still stored as a JSON STRING (.to_json), not a native Ruby
# Array -- the custom widget above still ultimately calls
# App.Setting.set(name, JSON.stringify(rows)), so the wire format is
# unchanged from the earlier textarea-based version. Every consumer --
# backend and frontend alike -- can always assume
# Setting.get('aux_status_options') is a JSON string and needs an
# explicit parse, regardless of which UI was used to edit it.
DEFAULT_AUX_STATUS_OPTIONS = [
  { 'value' => 'available',     'label' => 'Available',     'duration_minutes' => 0 },
  { 'value' => 'busy_lunch',    'label' => 'Busy Lunch',     'duration_minutes' => 30 },
  { 'value' => 'busy_meeting',  'label' => 'Busy Meeting',   'duration_minutes' => 60 },
  { 'value' => 'busy_training', 'label' => 'Busy Training',  'duration_minutes' => 60 },
  { 'value' => 'offline',       'label' => 'Offline',        'duration_minutes' => 0 },
].freeze

Setting.create_if_not_exists(
  title:       'AUX Status Options',
  name:        'aux_status_options',
  area:        'SISKA::AuxStatus',
  description: 'Daftar status AUX yang tersedia. Tambah atau hapus baris untuk menambah/mengurangi status -- durasi 0 menit berarti tidak ada batas waktu (tidak auto-expire). Value harus unik, huruf kecil, tanpa spasi.',
  options:     {},
  state:       DEFAULT_AUX_STATUS_OPTIONS.to_json,
  preferences: { controller: 'SettingsAreaAuxStatusOptions', permission: ['admin.system'] },
  frontend:    true,
)

# create_if_not_exists is a no-op on an existing record -- explicitly
# update preferences/description/options too, so re-running this script
# after the row-based UI was added (instead of the original textarea)
# actually switches an already-existing Setting over to it.
existing_setting = Setting.find_by(name: 'aux_status_options')
if existing_setting
  existing_setting.update!(
    description: 'Daftar status AUX yang tersedia. Tambah atau hapus baris untuk menambah/mengurangi status -- durasi 0 menit berarti tidak ada batas waktu (tidak auto-expire). Value harus unik, huruf kecil, tanpa spasi.',
    options:     {},
    preferences: { controller: 'SettingsAreaAuxStatusOptions', permission: ['admin.system'] },
  )
end

puts '== Setting: aux_status_routing_method =='
Setting.create_if_not_exists(
  title:       'AUX Status Routing Method',
  name:        'aux_status_routing_method',
  area:        'SISKA::AuxStatus',
  description: 'Strategi pemilihan agent Available saat distribusi tiket proaktif -- lihat docs/DESIGN_AUX_STATUS.md Section 2a.',
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'aux_status_routing_method',
        tag:     'select',
        options: {
          'leastrecent' => 'Least Recently Used (paling lama tidak dapat tiket)',
          'fewestcalls' => 'Fewest Calls (beban kerja tiket open aktif paling sedikit)',
          'roundrobin'  => 'Round Robin (gilir tetap berurutan)',
        },
      },
    ],
  },
  state:       'leastrecent',
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts '== Setting: aux_status_roundrobin_pointer (internal state, no Admin UI) =='
Setting.create_if_not_exists(
  title:       'AUX Status Round Robin Pointer (internal)',
  name:        'aux_status_roundrobin_pointer',
  area:        'SISKA::AuxStatus::Internal',
  description: 'Internal: user_id of the last agent picked by the roundrobin routing method. Read/written only by Service::AuxStatus::SelectAgent, not user-facing.',
  options:     {},
  state:       nil,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts '== Backfill: aux_status = available for existing agents =='
# Object Manager's data_option[:default] is a create-FORM default only --
# it never touches existing rows, and doesn't apply here anyway since
# aux_status is screens: {} (not on any form). Without this, every
# existing agent would read as aux_status: nil until they first touch
# the status dropdown -- handled defensively as "nil == available" in
# Service::AuxStatus::DistributeTicket too, but backfilling now also
# gives each agent a clean initial AuxStatusLog entry.
#
# Deliberately NOT using Service::AuxStatus::ChangeStatus here -- that
# would also fire DistributeTicket.pending_for for every agent in one
# go, which could bulk-reassign real pending unassigned tickets as a
# surprise side effect of running a setup script. This backfill only
# sets the column + seeds the log entry, no distribution side effect.
User.where(active: true).find_each do |u|
  next if !u.permissions?('ticket.agent')
  next if u.aux_status.present?

  AuxStatusLog.create!(user: u, status: 'available', started_at: Time.zone.now)
  u.update_columns(aux_status: 'available', aux_status_since: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
end

puts 'Done.'
