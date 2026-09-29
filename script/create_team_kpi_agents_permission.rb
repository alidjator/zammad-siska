# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Dedicated permission for seeing OTHER agents' numbers in the "KPI Tim"
# dashboard (tab Per agent, badge jumlah agent, sheet Agent di ekspor .xlsx,
# GET /api/v1/team_kpi/agents) -- see docs/DESIGN_TEAM_KPI_DASHBOARD.md
# Section 19.
#
# Deliberately NOT under 'report.*': Zammad grants every child of a
# permission a user holds (Auth::Permissions checks Permission.with_parents),
# so anyone with 'report' -- the whole "Customer Services" role, and even
# the "Client - Koordinator" customers -- would automatically hold a
# 'report.xxx' permission. Same pattern as Zammad's own 'chat' /
# 'knowledge_base': a disabled root that cannot be ticked in the UI, and an
# assignable child.
#
# Also creates (if missing) the additive role "Supervisor KPI" holding only
# 'team_kpi.agents', to be added on top of a user's normal role. The script
# assigns it to nobody -- do that via Admin > Manage > Users (or Roles).
#
#   bundle exec rails runner script/create_team_kpi_agents_permission.rb RAILS_ENV=production
Permission.create_if_not_exists(
  name:        'team_kpi',
  label:       'KPI Tim',
  description: 'Hak akses dashboard KPI Tim.',
  preferences: { disabled: true, prio: 1542 }, # after 'report' (1540) and 'report.unlimited_download' (1541)
)
Permission.create_if_not_exists(
  name:        'team_kpi.agents',
  label:       'Lihat KPI per agent',
  description: 'Boleh melihat angka agent lain di dashboard KPI Tim (tab Per agent, sheet Agent di ekspor, API /team_kpi/agents), terbatas pada grup yang bisa dibaca.',
  preferences: { prio: 1543 },
)

role = Role.find_by(name: 'Supervisor KPI')
if !role
  role = Role.create!(
    name:          'Supervisor KPI',
    note:          'Role tambahan: melihat KPI per agent di dashboard KPI Tim (team_kpi.agents). Tambahkan di atas role kerja user; tidak memberi akses grup.',
    active:        true,
    updated_by_id: 1,
    created_by_id: 1,
  )
end
role.permission_grant('team_kpi.agents') # idempotent

puts "permissions: #{Permission.where(name: %w[team_kpi team_kpi.agents]).pluck(:name).join(', ')}"
puts "role #{role.name} (id #{role.id}): #{role.permissions.pluck(:name).join(', ')}, users #{role.users.count}"
