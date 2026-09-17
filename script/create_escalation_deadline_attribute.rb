# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Custom Object Attribute for the Eskalasi "breach deadline" (see
# docs/DESIGN_ESCALATION_STATUS.md) -- a FIXED point in time, computed
# once when a ticket enters Eskalasi (escalation_started_at + effective
# budget hours, business-hours aware), not a continuously-decaying
# "time remaining" value. This lets it be used directly as a plain,
# sortable/filterable Overview column, same as native escalation_at.
#
#   bundle exec rails runner script/create_escalation_deadline_attribute.rb RAILS_ENV=production

UserInfo.current_user_id = 1

ObjectManager::Attribute.add(
  object:      'Ticket',
  name:        'escalation_deadline_at',
  display:     'Escalation Deadline At',
  data_type:   'datetime',
  data_option: {
    future: true,
    past:   true,
    diff:   0,
    null:   true,
    note:   'Internal: computed once by Service::Escalation::CalculateDeadlines when the ticket enters Eskalasi (escalation_started_at + effective budget hours, business-hours aware). Not editable by agents directly.',
  },
  active:      true,
  screens:     {},
  position:    1001,
)

ObjectManager::Attribute.migration_execute

Ticket.reset_column_information

puts 'Done.'
