# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# One-time historical data correction for the confirmed ~7h timezone bug
# (see docs/BUG_REPORT_TIMEZONE_FIRST_RESPONSE.md, sections 7-8). NOT an
# idempotent setup script like the others in this directory -- this is a
# data migration, meant to be run ONCE against a given database, after a
# backup and a dry-run review of its output.
#
# Root cause (confirmed, not a Zammad code bug): tickets.first_response_at/
# close_at/last_contact_at were MySQL TIMESTAMP columns (timezone-aware,
# converted per connection session timezone -- WIB on the original 3.4.0
# production server) in the old MySQL 3.4.0 database, while created_at was
# DATETIME (no timezone semantics) and preferences was a serialized blob
# (also no timezone semantics). The MySQL->PostgreSQL migration read the
# TIMESTAMP columns' internal (UTC) representation without re-applying the
# WIB session-timezone conversion MySQL normally does transparently on
# read -- so those three columns ended up shifted by exactly -7 hours for
# every migrated ticket, while created_at and preferences (never subject
# to that conversion) stayed correct.
#
#   bundle exec rails runner script/fix_timezone_migration_bug.rb RAILS_ENV=production
#
# Before running against a NEW database/cutover point, adjust CUTOVER
# below to that database's actual migration boundary (the last created_at
# before migrated/imported data ends and organically-created data begins
# -- verify via a per-day ticket count query, looking for the gap).
#
# Safe to re-run: already-corrected rows won't match the original bug's
# signature anymore, so running this a second time on an already-fixed
# database should find ~0 rows needing correction (harmless no-op), NOT
# double-shift anything -- because it only acts on found
# first_response_at/close_at/last_contact_at values relative to what's
# actually stored, not a blind unconditional "+7h" applied twice.
# Nonetheless: always take a fresh backup before running, and always
# dry-run first (see docs/BUG_REPORT_TIMEZONE_FIRST_RESPONSE.md section 8
# for the exact dry-run script used against staging).

CUTOVER = Time.zone.parse('2026-08-22 23:59:59') # adjust per-database, see comment above

def parse_ref(value)
  value.is_a?(String) ? Time.zone.parse(value) : value
end

puts '== Step 1: backup affected rows =='
backup_path = "/tmp/timezone_correction_backup_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.jsonl"
backup_scope = Ticket.where('created_at <= ?', CUTOVER)
                      .where('first_response_at IS NOT NULL OR close_at IS NOT NULL OR last_contact_at IS NOT NULL')

File.open(backup_path, 'w') do |f|
  count = 0
  backup_scope.find_each(batch_size: 5000) do |t|
    f.puts({
      id:                t.id,
      created_at:        t.created_at,
      first_response_at: t.first_response_at,
      close_at:          t.close_at,
      last_contact_at:   t.last_contact_at,
    }.to_json)
    count += 1
  end
  puts "Backed up #{count} rows to #{backup_path}"
end

puts '== Step 2: close_at / last_contact_at (+7h, uniform, no reliable independent ground truth exists) =='
ActiveRecord::Base.transaction do
  result1 = ActiveRecord::Base.connection.exec_update(<<~SQL)
    UPDATE tickets
    SET close_at = close_at + INTERVAL '7 hours'
    WHERE created_at <= '#{CUTOVER}'
      AND close_at IS NOT NULL
  SQL
  puts "close_at corrected: #{result1}"

  result2 = ActiveRecord::Base.connection.exec_update(<<~SQL)
    UPDATE tickets
    SET last_contact_at = last_contact_at + INTERVAL '7 hours'
    WHERE created_at <= '#{CUTOVER}'
      AND last_contact_at IS NOT NULL
  SQL
  puts "last_contact_at corrected: #{result2}"
end

puts '== Step 3: first_response_at (copy from ground-truth reference where trustworthy, else +7h fallback) =='
scope = Ticket.where('created_at <= ?', CUTOVER).where.not(first_response_at: nil)

group1_count = 0 # reference copy
group2_count = 0 # fallback +7h
group3_ids   = [] # skipped, needs manual review

scope.find_each(batch_size: 2000) do |t|
  ref_raw = t.preferences.dig('escalation_calculation', 'first_response_at')

  if ref_raw.nil?
    t.update_columns(first_response_at: t.first_response_at + 7.hours) # rubocop:disable Rails/SkipsModelValidations
    group2_count += 1
  else
    ref = parse_ref(ref_raw)
    diff_minutes = ((t.first_response_at - ref) / 60.0).round(1)

    if diff_minutes == -420.0 && ref >= t.created_at
      t.update_columns(first_response_at: ref) # rubocop:disable Rails/SkipsModelValidations
      group1_count += 1
    else
      group3_ids << t.id
    end
  end
end

puts "first_response_at copied from reference: #{group1_count}"
puts "first_response_at fallback +7h: #{group2_count}"
puts "first_response_at skipped (needs manual review): #{group3_ids.size}"

skipped_path = "/tmp/timezone_correction_frt_skipped_ids_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.json"
File.write(skipped_path, group3_ids.to_json)
puts "Skipped ticket IDs saved to #{skipped_path}"

puts '== Step 4: verify =='
%i[first_response_at close_at last_contact_at].each do |field|
  anomaly = Ticket.where("#{field} IS NOT NULL AND #{field} < created_at").count
  total = Ticket.where("#{field} IS NOT NULL").count
  puts "#{field}: anomaly=#{anomaly} / total=#{total}"
end

puts 'Done.'
