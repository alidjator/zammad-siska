# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Dedicated Group for internal QA/testing tickets (see
# docs/INCIDENT_EMAIL_NOTIFICATION_TESTING.md, recommendation #1) --
# deliberately created with ZERO members (no `groups_users` rows), so
# Transaction::Notification#possible_recipients_of_group (which reads
# User.group_access(group_id, 'full')) always resolves to an empty
# recipient list for tickets in this group. This prevents any real staff
# member from receiving a group-update notification email as a side
# effect of testing ticket status transitions, workflows, etc.
#
# IMPORTANT: keep this group members-less. Do not add real agents to it
# with 'full' (or any) access -- that would defeat its entire purpose.
# Future test tickets (Core Workflow verification, Eskalasi/CSAT trials,
# etc.) should be created directly in this group, or have a real
# ticket's group temporarily reassigned here before triggering any real
# state-changing save, and reassigned back afterward.
#
#   bundle exec rails runner script/create_qa_testing_group.rb RAILS_ENV=production

UserInfo.current_user_id = 1

Group.create_if_not_exists(
  name:   'QA - Internal Testing',
  active: true,
  note:   'Group khusus tiket pengujian internal SISKA -- SENGAJA tanpa anggota, supaya tiket test tidak memicu notifikasi email ke staf asli. Lihat docs/INCIDENT_EMAIL_NOTIFICATION_TESTING.md.',
)

group = Group.find_by(name: 'QA - Internal Testing')
member_count = ActiveRecord::Base.connection.select_value(
  ActiveRecord::Base.sanitize_sql_array(['SELECT count(*) FROM groups_users WHERE group_id = ?', group.id])
).to_i
raise "Aborting: expected 0 members, found #{member_count}" if member_count != 0

puts "Group '#{group.name}' (id=#{group.id}) created with #{member_count} members."
puts 'Done.'
