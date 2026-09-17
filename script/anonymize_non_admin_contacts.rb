# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# One-off anonymization of real customer/agent contact info on the SISKA
# staging instance (zammad-staging-zammad-app-1), requested after a
# complaint that test activity on staging caused real emails to reach
# real customers -- this staging DB is a full copy of production contact
# data with a live outbound SMTP connection.
#
# Scope (confirmed with user before running):
#   - users.email, users.login (synced to the same new value),
#     users.phone, users.mobile
#   - ALL users EXCEPT:
#       * Admin role (role_id 1)
#       * user id 1 (Zammad's internal system/"-" account)
#       * @pkp.co.id domain (internal PKP staff, incl. this project's own
#         service/integration accounts, e.g. integration-kpi-api@pkp.co.id
#         -- these are documented and relied on externally, and include
#         the operator's own login)
#   - phone/mobile only overwritten when the original value was actually
#     present (not null/blank) -- doesn't fabricate contact info that
#     never existed.
#   - Telegram is deliberately OUT of scope here -- no stable per-user
#     column exists for it (see docs/ACTIVITY_LOG_SISKA.md), it likely
#     only appears in ticket_articles.preferences (message-level, much
#     larger/riskier surface) -- needs separate investigation before any
#     decision.
#
# Done via a single raw SQL UPDATE (not ActiveRecord/`User#update`) so
# that NO Zammad callback/observer fires -- this deliberately triggers
# zero notifications to anyone, per explicit user instruction.
#
# New email/login: 'anon-<id>-<random>@anon.invalid' -- `.invalid` is the
# IETF-reserved TLD (RFC 2606) guaranteed to never resolve/deliver
# anywhere, and the `<id>` prefix guarantees global uniqueness on its own
# (users.login has a UNIQUE index) regardless of random-suffix collision.
#
# New phone/mobile: user id zero-padded to 16 digits (e.g. id 51 ->
# '0000000000000051') -- deliberately NOT a phone-number-shaped pattern
# (no valid-looking prefix/length), per explicit user request, so nobody
# mistakes it for a real number to dial/WhatsApp. Same value in both
# fields (no separate phone vs. mobile distinction needed once these are
# just placeholders), and trivially unique via the id itself.
#
# A JSONL backup of every affected row's OLD email/login/phone/mobile is
# written first (to the path below) before anything is overwritten --
# this is the one safety net kept even though the user asked to skip a
# separate dry-run cycle, since this mutates real customer PII at scale
# and is otherwise unrecoverable.
#
#   bundle exec rails runner script/anonymize_non_admin_contacts.rb RAILS_ENV=production

require 'json'

BACKUP_PATH = '/tmp/anonymize_contacts_backup_%s.jsonl' % Time.now.strftime('%Y%m%d_%H%M%S')

scope_sql = <<~SQL.squish
  FROM users
  WHERE id NOT IN (SELECT user_id FROM roles_users WHERE role_id = 1)
    AND id <> 1
    AND (email IS NULL OR email NOT ILIKE '%@pkp.co.id')
SQL

puts 'Backing up affected rows (old values) before any write...'
count = 0
File.open(BACKUP_PATH, 'w') do |f|
  ActiveRecord::Base.connection.select_all("SELECT id, email, login, phone, mobile #{scope_sql}").each do |row|
    f.puts(row.to_json)
    count += 1
  end
end
puts "Backed up #{count} rows to #{BACKUP_PATH}"

raise 'Aborting: backup row count looks wrong, expected ~72017' if count < 70_000 || count > 73_000

puts 'Running anonymization UPDATE (raw SQL, no callbacks, no notifications)...'

update_sql = <<~SQL.squish
  WITH targets AS (
    SELECT id,
           'anon-' || id || '-' || substr(md5(random()::text || id::text || clock_timestamp()::text), 1, 10) || '@anon.invalid' AS new_email
    #{scope_sql}
  )
  UPDATE users u
  SET email      = t.new_email,
      login      = t.new_email,
      phone      = CASE WHEN u.phone  IS NOT NULL AND u.phone  <> '' THEN lpad(u.id::text, 16, '0') ELSE u.phone  END,
      mobile     = CASE WHEN u.mobile IS NOT NULL AND u.mobile <> '' THEN lpad(u.id::text, 16, '0') ELSE u.mobile END,
      updated_at = now()
  FROM targets t
  WHERE u.id = t.id
SQL

result = ActiveRecord::Base.connection.execute(update_sql)
puts "Updated #{result.cmd_tuples} rows."
puts 'Done.'
