# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared safety guard for our custom Report::* adapters' `.items()`
# methods (Report::TicketFirstResponseTime, ::TicketFirstResponseTimeMean,
# ::TicketCsatScore) -- see docs/DESIGN_REPORTING_FRT.md.
#
# `.items()` has no LIMIT: it iterates every single matching ticket one
# at a time (`Ticket.find` + `#assets`) to build the download/Excel
# export. Confirmed on staging: an unrestricted "-all-" profile across
# several years ran for 100+ seconds without finishing (had to be
# force-killed) -- there is no natural ceiling, and a broad enough
# Profile + date range combination can hang the request indefinitely
# and burn real server CPU on a system also used for live operations.
#
# This is a cheap COUNT check (not the expensive per-ticket loop) run
# BEFORE that loop starts, so an over-broad request fails fast with a
# clear message instead of hanging.
module Report::DownloadLimitGuard
  def self.check!(count)
    max = Setting.get('report_download_max_records').to_i
    return if max.zero? || count <= max

    raise Exceptions::UnprocessableContent, "Terlalu banyak data untuk satu kali unduhan (#{count} tiket, batas saat ini #{max}). Persempit rentang waktu atau pilih Report Profile yang lebih spesifik. Batas ini bisa diubah di Admin > Settings > SISKA > Reporting."
  end
end
