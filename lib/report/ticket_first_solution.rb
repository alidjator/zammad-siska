# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# `.items` is guarded by Report::DownloadLimitGuard -- see that file and
# docs/DESIGN_REPORTING_FRT.md (native class, no upstream limit on the
# per-ticket asset-building loop below).
class Report::TicketFirstSolution < Report::BaseSql

=begin

  result = Report::TicketFirstSolution.aggs(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
    interval:    'month', # quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
  )

returns

  [4,5,1,5,0,51,5,56,7,4]

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
      ticket_list = Ticket.select('tickets.id, tickets.close_at, tickets.created_at').where(
        'tickets.close_at IS NOT NULL AND tickets.close_at >= ? AND tickets.close_at < ?',
        params[:range_start],
        params[:range_end],
      ).where(query, *bind_params).joins(tables)
      count = 0
      ticket_list.each do |ticket|
        closed_at  = ticket.close_at
        created_at = ticket.created_at
        if (closed_at - (60 * 15)) < created_at
          count += 1
        end
      end
      result.push count
      params[:range_start] = params[:range_end]
    end
    result
  end

=begin

  result = Report::TicketFirstSolution.items(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
    selector:    selector, # ticket selector to get only a collection of tickets
    timezone:    'Europe/Berlin',
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
    ticket_list = Ticket.select('tickets.id, tickets.close_at, tickets.created_at').where(
      'tickets.close_at IS NOT NULL AND tickets.close_at >= ? AND tickets.close_at < ?',
      params[:range_start],
      params[:range_end],
    ).where(query, *bind_params).joins(tables).reorder(close_at: :asc)

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

    # NOTE: `count` below is a POST-filter count (only tickets closed
    # within 15 minutes of creation count as "first solution") --
    # smaller than `total_count` above, which is the raw SQL match count
    # used for the sheet guard and, for a paginated preview request,
    # for the pager's total/page-count math. This means the preview
    # pager's page-count can be a little optimistic (some SQL-matched
    # rows on a given page don't pass this post-filter, so the true
    # final page can render with fewer rows than a full page) -- a
    # pre-existing quirk of this metric being post-filtered at all, not
    # something pagination introduces.
    count = 0
    assets = {}
    ticket_ids = []
    ticket_list.each do |ticket|
      closed_at  = ticket.close_at
      created_at = ticket.created_at
      if (closed_at - (60 * 15)) < created_at
        count += 1
        ticket_ids.push ticket.id
      end
      ticket_full = Ticket.find(ticket.id)
      assets = ticket_full.assets(assets)
    end
    {
      count:      params[:sheet] ? count : total_count,
      ticket_ids: ticket_ids,
      assets:     assets,
    }
  end

end
