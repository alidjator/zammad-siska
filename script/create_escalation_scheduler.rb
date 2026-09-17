# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Registers the periodic job that (re)computes Ticket#escalation_deadline_at
# for every ticket currently in the "eskalasi" state (see
# docs/DESIGN_ESCALATION_STATUS.md and
# app/services/service/escalation/calculate_deadlines.rb).
#
# Unlike the CSAT survey scheduler, this one is safe to run `active: true`
# from the start -- it only recomputes an internal ticket field, it never
# sends anything to a customer.
#
#   bundle exec rails runner script/create_escalation_scheduler.rb RAILS_ENV=production

Scheduler.create_if_not_exists(
  name:      'Eskalasi: calculate escalation deadlines',
  method:    'Service::Escalation::CalculateDeadlines.run',
  period:    300,
  prio:      2,
  active:    true,
  created_by_id: 1,
  updated_by_id: 1,
)

puts 'Done.'
