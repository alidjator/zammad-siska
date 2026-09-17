# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Dedicated bypass permission for the Reporting download-size guard
# (Report::DownloadLimitGuard, lib/report/download_limit_guard.rb --
# see docs/DESIGN_REPORTING_FRT.md). A user holding this permission
# skips the `report_download_max_records` check entirely.
#
# Deliberately a NEW, narrow permission -- not 'report' (held by
# everyone who can open Reporting at all, which would make the limit
# meaningless for most real users) and not 'admin.system' (ties an
# unrelated capability to general system-settings access). This way
# the limit stays on by default for everyone, and an admin can
# consciously exempt specific people/roles who genuinely need large
# one-off downloads and accept the slower request themselves.
#
# Not assigned to any Role by this script -- assign it via Admin >
# Manage > Roles > (pick a role) > Permissions > find "Reporting" >
# check "Unlimited Report Download", same as any other permission.
#
#   bundle exec rails runner script/create_report_unlimited_download_permission.rb RAILS_ENV=production

Permission.create_if_not_exists(
  name:        'report.unlimited_download',
  label:       'Unlimited Report Download',
  description: 'Bypass the Reporting download-size limit (Setting report_download_max_records) -- can download an unlimited number of records in one request, at the cost of a possibly very slow request.',
  preferences: { prio: 1541 }, # right after 'report' (prio 1540)
)

puts 'Done.'
