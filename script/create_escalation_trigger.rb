# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Trigger that sets ticket.escalation_started_at when a ticket's state
# changes to "eskalasi" (see docs/DESIGN_ESCALATION_STATUS.md).
#
# execution_condition_mode: 'selective' is what makes this fire only on
# the transition INTO eskalasi (state_id actually changing), not on every
# subsequent save while already in that state, and correctly re-fires if
# a ticket leaves and re-enters Eskalasi later.
#
# operator: 'relative' on a datetime perform action is computed at the
# moment the trigger actually runs (Time.zone.now + N), not a fixed
# value baked in when the trigger was configured -- confirmed via
# lib/time_range_helper.rb. The Admin UI's own value picker only offers
# 1-120 (never 0), but the backend has no such floor, so this script
# sets it directly to 0 (fire immediately) for the most accurate
# "started now" timestamp -- bypassing that UI-only restriction.
#
#   bundle exec rails runner script/create_escalation_trigger.rb RAILS_ENV=production

Trigger.create_if_not_exists(
  name:                     'Eskalasi: set escalation_started_at',
  condition:                {
    'ticket.state_id' => {
      'operator' => 'is',
      'value'    => [Ticket::State.find_by!(name: 'eskalasi').id],
    },
  },
  perform:                  {
    'ticket.escalation_started_at' => {
      'operator' => 'relative',
      'range'    => 'minute',
      'value'    => '0',
    },
  },
  activator:                'action',
  execution_condition_mode: 'selective',
  active:                   true,
  created_by_id:            1,
  updated_by_id:            1,
)

puts 'Done.'
