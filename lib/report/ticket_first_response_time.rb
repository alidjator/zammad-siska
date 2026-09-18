# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Median First Response Time (in minutes) per interval bucket.
#
# Median rather than mean: a handful of neglected tickets answered days
# late in a single catch-up batch can otherwise dominate the average and
# make it unrepresentative, especially with the small sample sizes left
# after the data-integrity filter below.
#
# NOTE: a known data-integrity issue makes `first_response_at` (and
# `close_at`, `last_contact_at`) ~7h earlier than `created_at` for a large
# share of historical tickets (see docs/BUG_REPORT_TIMEZONE_FIRST_RESPONSE.md
# on `main`). Rather than guessing a cutover date, every query here excludes
# tickets where `first_response_at < created_at` outright -- this is
# self-correcting once the underlying bug is actually fixed, and it doesn't
# discard the historical tickets that were recorded correctly.
#
# `.items` (used by the Reporting download/Excel export) is guarded by
# Report::DownloadLimitGuard -- see lib/report/download_limit_guard.rb
# and docs/DESIGN_REPORTING_FRT.md for why: it has no LIMIT and iterates
# every matching ticket individually, so an over-broad Profile + date
# range can otherwise hang the request indefinitely.
class Report::TicketFirstResponseTime < Report::BaseSql

=begin

  result = Report::TicketFirstResponseTime.aggs(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
    interval:    'month', # quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
  )

returns

  [12,9,15,8,0,21,10,18,7,14]  # median first response time in minutes, per bucket

=end

  def self.aggs(params_origin)
    params = duplicate_preserving_current_user(params_origin)

    result = []
    case params[:interval]
    when 'month'
      stop_interval = 12
    when 'week'
      stop_interval = 7
    when 'day'
      stop_interval = 31
    when 'hour'
      stop_interval = 24
    when 'minute'
      stop_interval = 60
    end
    (1..stop_interval).each do |_counter|
      case params[:interval]
      when 'month'
        params[:range_end] = params[:range_start].next_month
      when 'week', 'day'
        params[:range_end] = params[:range_start].next_day
      when 'hour'
        params[:range_end] = params[:range_start] + 1.hour
      when 'minute'
        params[:range_end] = params[:range_start] + 1.minute
      end

      local_selector = params[:selector].clone
      local_selector.merge!(without_merged_tickets_selector) # do not show merged tickets in reports

      query, bind_params, tables = Ticket.selector2sql(local_selector)
      diffs = Ticket
        .where(
          'tickets.first_response_at IS NOT NULL AND tickets.first_response_at >= tickets.created_at AND tickets.created_at >= ? AND tickets.created_at < ?',
          params[:range_start],
          params[:range_end],
        )
        .where(query, *bind_params).joins(tables)
        .pluck(:created_at, :first_response_at)
        .map { |created_at, first_response_at| first_response_at - created_at }

      result.push(diffs.blank? ? -0.001 : (median(diffs) / 60).to_i)

      params[:range_start] = params[:range_end]
    end
    result
  end

=begin

  result = Report::TicketFirstResponseTime.items(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
    selector:    selector, # ticket selector to get only a collection of tickets
  )

returns

  {
    count: 123,
    ticket_ids: [4,5,1,5,0,51,5,56,7,4],
    assets: assets,
  }

=end

  def self.items(params)
    local_selector = params[:selector].clone
    local_selector.merge!(without_merged_tickets_selector) # do not show merged tickets in reports

    query, bind_params, tables = Ticket.selector2sql(local_selector)
    ticket_list = Ticket.select('tickets.id, tickets.first_response_at, tickets.created_at').where(
      'tickets.first_response_at IS NOT NULL AND tickets.first_response_at >= tickets.created_at AND tickets.created_at >= ? AND tickets.created_at < ?',
      params[:range_start],
      params[:range_end],
    ).where(query, *bind_params).joins(tables).reorder(created_at: :asc)

    total_count = ticket_list.count(:id)

    # sheet (Excel export) still needs every matching row -- guarded as
    # before. On-screen preview is paginated instead (Section 7,
    # docs/DESIGN_REPORTING_FRT.md) and skips the guard entirely, since
    # a bounded page is safe regardless of the total match count.
    if params[:sheet]
      Report::DownloadLimitGuard.check!(total_count, user: params[:current_user])
    else
      ticket_list = Report::ItemsPaginator.apply(ticket_list, params)
    end

    assets = {}
    ticket_ids = []
    ticket_list.each do |ticket|
      ticket_ids.push ticket.id
      ticket_full = Ticket.find(ticket.id)
      assets = ticket_full.assets(assets)
    end
    {
      count:      total_count,
      ticket_ids: ticket_ids,
      assets:     assets,
    }
  end

  def self.median(values)
    sorted = values.sort
    len    = sorted.length
    mid    = len / 2

    return sorted[mid] if len.odd?

    (sorted[mid - 1] + sorted[mid]) / 2.0
  end
  private_class_method :median

end
