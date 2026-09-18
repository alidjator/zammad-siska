# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Server-side pagination for Report `.items()` on-screen preview
# requests, added after a real survey of this org's Report Profiles
# (docs/DESIGN_REPORTING_FRT.md Section 7) found ~10% of realistic
# profile+range combinations -- including "-all-" for the current year,
# arguably the single most likely default choice -- already exceed
# Setting report_download_max_records (Report::DownloadLimitGuard),
# meaning the preview table couldn't be viewed at all without narrowing
# filters first.
#
# Deliberately separate from Report::DownloadLimitGuard, not a
# replacement for it: an actual Excel/sheet EXPORT (params[:sheet] true)
# still needs every matching row materialized to build the spreadsheet
# -- that's still guarded exactly as before. Only the JSON on-screen
# PREVIEW path is paginated here, and it skips the guard entirely for
# that path: a bounded LIMIT/OFFSET page is safe regardless of how many
# rows match in total.
module Report::ItemsPaginator
  # MAX_PER_PAGE is a hardcoded safety CEILING, not admin-configurable on
  # purpose -- Setting report_preview_per_page (below) controls the
  # normal/default page size, but this caps whatever a client asks for
  # (including a mis-set Setting or a direct API call), so a too-high
  # value can't accidentally make every preview page as expensive as a
  # small export.
  MAX_PER_PAGE = 200

  # `relation` must already be `.count`-safe (a single-column .select,
  # matching the same convention Report::DownloadLimitGuard.check! calls
  # rely on -- see lib/report/download_limit_guard.rb for why a bare
  # `.count` breaks on these queries).
  def self.apply(relation, params)
    page     = [params[:page].to_i, 1].max
    per_page = params[:per_page].to_i
    per_page = default_per_page if per_page <= 0
    per_page = MAX_PER_PAGE if per_page > MAX_PER_PAGE

    relation.limit(per_page).offset((page - 1) * per_page)
  end

  def self.default_per_page
    value = Setting.get('report_preview_per_page').to_i
    return 50 if value <= 0

    value
  end
end
