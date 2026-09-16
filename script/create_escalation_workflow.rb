# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Core Workflow rule enforcing the Open -> In Progress -> Eskalasi part of
# the SISKA status sequence (see docs/DESIGN_ESCALATION_STATUS.md,
# gap analysis item No. 12): a ticket currently in "open" cannot be moved
# directly to "eskalasi", it must pass through "in progress" first.
#
# Deliberately NOT enforcing a fully rigid Open->In Progress->Eskalasi->
# Closed chain: "closed" stays reachable from open/in progress/eskalasi
# directly, since most tickets resolve without ever needing escalation --
# forcing every ticket through every intermediate state would break
# normal day-to-day resolution. Only the specific "skip straight to
# Eskalasi" jump is restricted, since that's the one the requirement
# actually called out.
#
# This is enforced server-side on save (Ticket#validate_workflows via
# CoreWorkflow::Result::RemoveOption -> check_restrict_values), not just
# hidden in the browser dropdown -- confirmed in
# app/models/concerns/checks_core_workflow.rb.
#
# No role restriction is applied here on purpose (see
# docs/DESIGN_ESCALATION_STATUS.md section 3) -- an admin can add a
# `session.role_ids` condition to this same workflow later via
# Manage > Core Workflows, no code change needed.
#
#   bundle exec rails runner script/create_escalation_workflow.rb RAILS_ENV=production

# Both state IDs are stringified -- CoreWorkflow's option-restriction
# machinery (CoreWorkflow::Result::RemoveOption) compares against a
# baseline candidate list built from STRING option values
# (CoreWorkflow::Attributes::TicketState#values), and Ruby's Array#-
# does no cross-type coercion (9 != '9'). Storing integers here silently
# no-ops the whole rule -- confirmed by reproducing it end-to-end via
# CoreWorkflow::Result::RemoveOption directly before finding this.
open_state_id     = Ticket::State.find_by!(name: 'open').id.to_s
eskalasi_state_id = Ticket::State.find_by!(name: 'eskalasi').id.to_s

CoreWorkflow.create_if_not_exists(
  name:            'SISKA - Eskalasi must pass through In Progress',
  object:          'Ticket',
  condition_saved: {
    'ticket.state_id' => {
      'operator' => 'is',
      'value'    => [open_state_id],
    },
  },
  perform:         {
    'ticket.state_id' => {
      'operator'      => 'remove_option',
      'remove_option' => [eskalasi_state_id],
    },
  },
  preferences:     { 'screen' => %w[edit] },
  changeable:      true,
  active:          true,
  created_by_id:   1,
  updated_by_id:   1,
)

puts 'Done.'
