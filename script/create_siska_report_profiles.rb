# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Creates Report Profiles for SISKA (gap analysis item No. 7), broken down
# by Category, Group, and top Organizations by ticket volume.
#
# Not placed under db/seeds/ on purpose: db/seeds.rb only runs against a
# completely empty database (`return` early if `User.any?`), so it would
# never execute here. Run manually instead, and safe to re-run any time
# (e.g. after new groups are added, or an organization's ticket volume
# crosses the threshold) since Report::Profile.create_if_not_exists skips
# profiles that already exist:
#
#   bundle exec rails runner script/create_siska_report_profiles.rb RAILS_ENV=production

ORGANIZATION_MIN_TICKETS = 20

puts '== Category =='
category_attr = ObjectManager::Attribute.get(object: 'Ticket', name: 'category')
category_attr&.data_option&.dig('options')&.each do |value, label|
  next if value == 'no_category'

  Report::Profile.create_if_not_exists(
    name:          "Category: #{label}",
    condition:     { 'ticket.category' => { 'operator' => 'is', 'value' => value } },
    active:        true,
    updated_by_id: 1,
    created_by_id: 1,
  )
  puts "  #{label}"
end

puts '== Group =='
Group.where(active: true).order(:name).each do |group|
  Report::Profile.create_if_not_exists(
    name:          "Group: #{group.name}",
    condition:     { 'ticket.group_id' => { 'operator' => 'is', 'value' => group.id.to_s } },
    active:        true,
    updated_by_id: 1,
    created_by_id: 1,
  )
  puts "  #{group.name}"
end

puts "== Organization (>= #{ORGANIZATION_MIN_TICKETS} tickets) =="
Ticket.group(:organization_id).having('count(*) >= ?', ORGANIZATION_MIN_TICKETS).count.each do |organization_id, count|
  next if organization_id.nil?

  organization = Organization.find_by(id: organization_id)
  next if !organization

  Report::Profile.create_if_not_exists(
    name:          "Organization: #{organization.name}",
    condition:     { 'ticket.organization_id' => { 'operator' => 'is', 'value' => organization.id.to_s } },
    active:        true,
    updated_by_id: 1,
    created_by_id: 1,
  )
  puts "  #{organization.name} (#{count} tickets)"
end

puts 'Done.'
