# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Dedicated permission for supervisor/admin to change ANOTHER agent's
# AUX status (Service::AuxStatus::ChangeStatus#authorize! -- see
# docs/DESIGN_AUX_STATUS.md Section 4 poin 5 / 5.8). An agent changing
# their OWN status needs no special permission (standard 'ticket.agent'
# already covers that, checked at the controller level, not here).
#
# Deliberately a NEW, narrow permission -- not 'admin.user' (much wider,
# ties an unrelated capability to general user-management access).
#
# Not assigned to any Role by this script -- assign it via Admin >
# Manage > Roles > (pick a role) > Permissions > find "AUX Status" >
# check "Override AUX Status".
#
#   bundle exec rails runner script/create_aux_status_override_permission.rb RAILS_ENV=production

Permission.create_if_not_exists(
  name:        'aux_status.override',
  label:       'Override AUX Status',
  description: 'Change another agent\'s AUX status (Available/Busy/Offline) on their behalf, bypassing the self-only restriction.',
  preferences: { prio: 1720 }, # right after the highest existing prio (1710)
)

puts 'Done.'
