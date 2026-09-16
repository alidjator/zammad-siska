# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Creates the ticket states, Custom Object Attributes, and Setting needed
# for the "Eskalasi" status workflow (see docs/DESIGN_ESCALATION_STATUS.md
# -- gap analysis item No. 3 & 12). Run once via:
#
#   bundle exec rails runner script/create_escalation_object_attributes.rb RAILS_ENV=production
#
# Safe to re-run: create_if_not_exists / ObjectManager::Attribute.add (no
# force:) are all no-ops on records that already exist.

UserInfo.current_user_id = 1

puts '== Ticket::State: In Progress =='
Ticket::State.create_if_not_exists(
  name:          'in progress',
  state_type_id: Ticket::StateType.find_by!(name: 'open').id,
)

puts '== Ticket::State: Eskalasi =='
# ignore_escalation left false (default) on purpose -- native SLA
# (escalation_at, never resets from created_at) keeps running in
# parallel with the new custom escalation_started_at-based clock below,
# rather than being frozen. Admin can flip this to true anytime via
# Manage > Ticket States, no code/redeploy needed -- see
# docs/DESIGN_ESCALATION_STATUS.md section 4 for the tradeoff.
Ticket::State.create_if_not_exists(
  name:          'eskalasi',
  state_type_id: Ticket::StateType.find_by!(name: 'open').id,
)

puts '== Ticket: escalation_started_at =='
ObjectManager::Attribute.add(
  object:      'Ticket',
  name:        'escalation_started_at',
  display:     'Escalation Started At',
  data_type:   'datetime',
  data_option: {
    future: true,
    past:   true,
    diff:   0,
    null:   true,
    note:   'Internal: when the ticket last entered the Eskalasi state. Set by a Trigger, not editable by agents directly.',
  },
  active:      true,
  screens:     {},
  position:    1000,
)

puts '== Group: escalation_budget_hours =='
ObjectManager::Attribute.add(
  object:      'Group',
  name:        'escalation_budget_hours',
  display:     'Escalation Budget (business hours)',
  data_type:   'integer',
  data_option: {
    default: '',
    min:     1,
    max:     999,
    null:    true,
    note:    'How many business hours after entering Eskalasi this Group\'s tickets are allowed before being considered breached. Leave blank to use the global default (Setting escalation_budget_hours). Takes priority over the Organization-level override if both are set.',
  },
  active:      true,
  screens:     {
    edit: {
      '-all-' => {
        shown: true,
        null:  true,
      },
    },
  },
  position:    600,
)

puts '== Organization: escalation_budget_hours =='
ObjectManager::Attribute.add(
  object:      'Organization',
  name:        'escalation_budget_hours',
  display:     'Escalation Budget (business hours)',
  data_type:   'integer',
  data_option: {
    default: '',
    min:     1,
    max:     999,
    null:    true,
    note:    'How many business hours after entering Eskalasi this Organization\'s tickets are allowed before being considered breached. Leave blank to use the global default (Setting escalation_budget_hours). Overridden by the Group-level setting if both are set for a given ticket.',
  },
  active:      true,
  screens:     {
    edit: {
      '-all-' => {
        shown: true,
        null:  true,
      },
    },
  },
  position:    600,
)

puts '== Apply pending schema migrations =='
ObjectManager::Attribute.migration_execute

Ticket.reset_column_information
Group.reset_column_information
Organization.reset_column_information

puts '== Setting: escalation_budget_hours (global default) =='
Setting.create_if_not_exists(
  title:       'Escalation Budget (business hours, global default)',
  name:        'escalation_budget_hours',
  area:        'Escalation::Base',
  description: 'Default number of business hours after a ticket enters Eskalasi before it is considered breached, when neither the ticket\'s Group nor Organization overrides it (Group wins if both are set).',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'escalation_budget_hours',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  state:       8,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts 'Done.'
