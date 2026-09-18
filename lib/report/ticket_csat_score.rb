# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Average CSAT score (1-5) per interval bucket, for tickets closed in that
# bucket that have a submitted rating.
#
# Bucketed by close_at (not csat_submitted_at) to match the convention
# already used by the built-in "closed" metric (Report::TicketGenericTime,
# field: 'close_at') -- "CSAT for tickets closed in period X", not "ratings
# received in period X".
#
# Uses a plain average, unlike Report::TicketFirstResponseTime's median:
# csat_score is bounded 1-5, so it isn't vulnerable to the multi-day-outlier
# skew that motivated using median for FRT, and average is the standard,
# expected way to summarize a bounded satisfaction scale.
#
# `.items` is guarded by Report::DownloadLimitGuard -- see that file and
# docs/DESIGN_REPORTING_FRT.md.
class Report::TicketCsatScore < Report::BaseSql

=begin

  result = Report::TicketCsatScore.aggs(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
    interval:    'month', # quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
  )

returns

  [4.2, 3.8, 4.6, 0, -0.001, ...]  # average CSAT score per bucket, -0.001 if no ratings

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
      scores = Ticket
        .where(
          'tickets.csat_score IS NOT NULL AND tickets.close_at >= ? AND tickets.close_at < ?',
          params[:range_start],
          params[:range_end],
        )
        .where(query, *bind_params).joins(tables)
        .pluck(:csat_score)

      result.push(scores.blank? ? -0.001 : (scores.sum.to_f / scores.size).round(2))

      params[:range_start] = params[:range_end]
    end
    result
  end

=begin

  result = Report::TicketCsatScore.items(
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
    ticket_list = Ticket.select('tickets.id, tickets.csat_score, tickets.close_at').where(
      'tickets.csat_score IS NOT NULL AND tickets.close_at >= ? AND tickets.close_at < ?',
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

end
