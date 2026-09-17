# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Registers the periodic job that reverts any agent's timed aux_status
# (Busy Lunch/Meeting/Training) back to Available once
# User#aux_status_expires_at has passed (see docs/DESIGN_AUX_STATUS.md
# Section 5.4 and app/services/service/aux_status/expire_statuses.rb).
#
# period: 60 (every 1 minute) -- much more frequent than the Eskalasi
# scheduler's 5 minutes, because the shortest AUX duration is 30 minutes
# and any delay reverting to Available is directly felt by the agent, not
# just a backend metric.
#
# Safe to run `active: true` from the start -- same reasoning as the
# Eskalasi scheduler: it only recomputes internal fields, never sends
# anything to a customer.
#
#   bundle exec rails runner script/create_aux_status_scheduler.rb RAILS_ENV=production

Scheduler.create_if_not_exists(
  name:          'AUX Status: expire timed statuses',
  method:        'Service::AuxStatus::ExpireStatuses.run',
  period:        60,
  prio:          2,
  active:        true,
  created_by_id: 1,
  updated_by_id: 1,
)

puts 'Done.'
