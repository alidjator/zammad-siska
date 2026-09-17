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
# Design refinement made during implementation (not in the original
# Section 5.2 draft): the list of AUX status VALUES itself does not need
# its own dedicated Setting -- it's already natively editable via
# Admin > Manage > Attributes (Object Manager) since `aux_status` below
# is a plain `select` attribute, and Zammad's Object Manager UI already
# supports adding/removing select options without code changes. Only the
# per-status DURATION (which Object Manager select options can't carry as
# metadata) needs a dedicated Setting -- see `aux_status_durations` below.

UserInfo.current_user_id = 1

puts '== User: aux_status =='
# screens: {} on purpose -- not editable via the generic User edit/create
# form, same pattern as Ticket#escalation_started_at in Fase 3. The only
# supported way to change it is via Service::AuxStatus::ChangeStatus
# (through the dedicated API/UI in Section 5.7), which enforces the
# self-or-override permission check.
ObjectManager::Attribute.add(
  object:      'User',
  name:        'aux_status',
  display:     'AUX Status',
  data_type:   'select',
  data_option: {
    default:   'available',
    options:   {
      'available'     => 'Available',
      'busy_lunch'    => 'Busy Lunch',
      'busy_meeting'  => 'Busy Meeting',
      'busy_training' => 'Busy Training',
      'offline'       => 'Offline',
    },
    null:      false,
    note:      'Internal: current AUX status. Only changeable via the AUX Status widget/API, not this form -- see docs/DESIGN_AUX_STATUS.md.',
    translate: true,
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

puts '== Setting: aux_status_durations =='
# Minutes per status value; a status not present here (or with a nil/0
# value) is treated as durationless (never auto-expires). Covers the
# standard set decided in docs/DESIGN_AUX_STATUS.md Section 4 -- if an
# admin later adds a brand-new select option via Object Manager (e.g.
# "Busy Coaching"), it defaults to durationless unless this hash is also
# updated (Setting.set('aux_status_durations', ...) works for any key,
# even ones the fixed Admin UI form below doesn't have a field for yet).
Setting.create_if_not_exists(
  title:       'AUX Status Durations (minutes)',
  name:        'aux_status_durations',
  area:        'SISKA::AuxStatus',
  description: 'How many minutes each timed AUX status lasts before auto-reverting to Available. Statuses not listed here (or set to 0) never auto-expire.',
  options:     {
    form: [
      { display: 'Busy Lunch (menit)',    null: true, name: 'busy_lunch',    tag: 'input', type: 'number' },
      { display: 'Busy Meeting (menit)',  null: true, name: 'busy_meeting',  tag: 'input', type: 'number' },
      { display: 'Busy Training (menit)', null: true, name: 'busy_training', tag: 'input', type: 'number' },
    ],
  },
  state:       { 'busy_lunch' => 30, 'busy_meeting' => 60, 'busy_training' => 60 },
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

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
