# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# One-off export: real (unmasked) before-vs-after contact data for the
# non-admin anonymization run (see script/anonymize_non_admin_contacts.rb
# and docs/ANONYMIZATION_CONTACT_INFO.md). This file is for internal
# audit use ONLY -- it contains real customer PII and must NEVER be
# committed to git (unlike ANONYMIZATION_CONTACT_INFO.md, which uses
# masked examples specifically so it's safe to commit).
#
#   bundle exec rails runner script/export_anonymization_before_after.rb RAILS_ENV=production

require 'json'
require 'write_xlsx'

BACKUP_PATH = '/tmp/anonymize_contacts_backup_20260917_010218.jsonl'
OUT_PATH    = '/tmp/anonymization_before_after.xlsx'

before_by_id = {}
File.foreach(BACKUP_PATH) do |line|
  row = JSON.parse(line)
  before_by_id[row['id']] = row
end
puts "Loaded #{before_by_id.size} backup rows."

workbook  = WriteXLSX.new(OUT_PATH)
worksheet = workbook.add_worksheet('Before vs After')
header_format = workbook.add_format(bold: true, bg_color: 'gray', color: 'white')

headers = %w[id email_before login_before phone_before mobile_before email_after login_after phone_after mobile_after]
headers.each_with_index { |h, i| worksheet.write(0, i, h, header_format) }

row_num = 1
before_by_id.keys.each_slice(5_000) do |id_batch|
  sql = "SELECT id, email, login, phone, mobile FROM users WHERE id IN (#{id_batch.join(',')})"
  after_by_id = {}
  ActiveRecord::Base.connection.select_all(sql).each { |r| after_by_id[r['id']] = r }

  id_batch.each do |id|
    b = before_by_id[id]
    a = after_by_id[id]
    next if a.nil?

    worksheet.write(row_num, 0, id)
    worksheet.write(row_num, 1, b['email'])
    worksheet.write(row_num, 2, b['login'])
    worksheet.write(row_num, 3, b['phone'])
    worksheet.write(row_num, 4, b['mobile'])
    worksheet.write(row_num, 5, a['email'])
    worksheet.write(row_num, 6, a['login'])
    worksheet.write(row_num, 7, a['phone'])
    worksheet.write(row_num, 8, a['mobile'])
    row_num += 1
  end
end

workbook.close
puts "Wrote #{row_num - 1} rows to #{OUT_PATH}"
