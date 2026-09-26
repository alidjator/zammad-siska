# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Creates (or reuses) a service account for an external app that reads the
# "KPI Tim" API, and issues it a new API token -- see
# docs/INTEGRASI_WEB_PORTAL_KPI.md and docs/INTEGRASI_LARAVEL_KPI.md.
#
# One account per consuming app, so a token can be rotated/revoked without
# touching the others and access shows up per app. The account gets the
# "Customer Services" role, which reads every operational group except
# "QA - Internal Testing" -- the same scope as integration-kpi-api@pkp.co.id,
# so every app sees the same team numbers. The token is limited to the
# given permissions (ticket.agent for team totals, + report for the
# per-agent breakdown /team_kpi/agents), not the role's full set.
#
# Use a @pkp.co.id address: script/anonymize_non_admin_contacts.rb keeps
# that domain untouched.
#
# Usage (staging container or production):
#   rails runner script/create_kpi_integration_account.rb EMAIL "First name" PERMISSIONS "Token name"
#   rails runner script/create_kpi_integration_account.rb integration-kpi-laravel@pkp.co.id \
#     "KPI Tim Laravel" ticket.agent,report "KPI Tim Laravel API access"
#
# Prints the token once -- store it in the app's secret store right away,
# it cannot be shown again.

email, firstname, permissions, token_name = ARGV
abort 'usage: EMAIL "First name" PERMISSIONS "Token name"' if [email, firstname, permissions, token_name].any?(&:blank?)
abort 'use a @pkp.co.id address (kept by the anonymization script)' if !email.end_with?('@pkp.co.id')

permissions = permissions.split(',').map(&:strip)
allowed     = %w[ticket.agent report]
abort "permissions must be a subset of #{allowed.join(',')}" if (permissions - allowed).any? || permissions.exclude?('ticket.agent')

role = Role.find_by!(name: 'Customer Services')

user = User.find_by(email: email)
if user
  puts "account exists: #{email} (id #{user.id})"
else
  user = User.create!(
    login:         email,
    email:         email,
    firstname:     firstname,
    lastname:      'Integration',
    active:        true,
    role_ids:      [role.id],
    note:          'Service account for the KPI Tim API (script/create_kpi_integration_account.rb). Not a person -- do not assign tickets.',
    updated_by_id: 1,
    created_by_id: 1,
  )
  puts "account created: #{email} (id #{user.id})"
end
user.update!(role_ids: (user.role_ids | [role.id])) if user.role_ids.exclude?(role.id)

token = Token.create!(action: 'api', persistent: true, user_id: user.id, name: token_name, preferences: { permission: permissions })

puts "groups readable: #{user.group_ids_access('read').size}"
puts "token (#{token_name}, #{permissions.join('+')}): #{token.token}"
