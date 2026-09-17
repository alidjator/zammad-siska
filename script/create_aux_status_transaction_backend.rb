# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Registers Transaction::AuxStatusDistribution (app/models/transaction/
# aux_status_distribution.rb) as an async Transaction Backend -- the
# native mechanism Zammad uses for "run custom code whenever a record is
# created/updated" (see e.g. Transaction::ClearbitEnrichment,
# Transaction::CtiCallerIdDetection in db/seeds/settings.rb). This is
# what makes the proactive ticket push actually run whenever a new
# ticket is created -- see docs/DESIGN_AUX_STATUS.md Section 5.5.
#
#   bundle exec rails runner script/create_aux_status_transaction_backend.rb RAILS_ENV=production

UserInfo.current_user_id = 1

puts '== Setting: 9300_aux_status_distribution =='
Setting.create_if_not_exists(
  title:       'Defines transaction backend.',
  name:        '9300_aux_status_distribution',
  area:        'Transaction::Backend::Async',
  description: 'Defines the transaction backend which proactively distributes newly-created unassigned tickets to an Available agent (Fase 4 AUX Status).',
  options:     {},
  state:       'Transaction::AuxStatusDistribution',
  frontend:    false,
)

puts 'Done.'
