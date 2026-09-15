# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Average First Response Time (in minutes) per interval bucket.
#
# Reuses Report::Base#time_average, which already computes the average
# duration from ticket creation to a given timestamp field for tickets
# matching a condition within one time range (present in Zammad core but
# not wired into any active report metric).
class Report::TicketFirstResponseTime < Report::BaseSql

=begin

  result = Report::TicketFirstResponseTime.aggs(
    range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
    range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
    interval:    'month', # quarter, month, week, day, hour, minute, second
    selector:    selector, # ticket selector to get only a collection of tickets
  )

returns

  [12,9,15,8,0,21,10,18,7,14]  # average first response time in minutes, per bucket

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

      avg = time_average(
        type:      'first_response_at',
        start:     params[:range_start],
        end:       params[:range_end],
        condition: local_selector,
      )
      result.push avg[:count]

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
      'tickets.first_response_at IS NOT NULL AND tickets.created_at >= ? AND tickets.created_at < ?',
      params[:range_start],
      params[:range_end],
    ).where(query, *bind_params).joins(tables).reorder(created_at: :asc)

    assets = {}
    ticket_ids = []
    ticket_list.each do |ticket|
      ticket_ids.push ticket.id
      ticket_full = Ticket.find(ticket.id)
      assets = ticket_full.assets(assets)
    end
    {
      count:      ticket_ids.count,
      ticket_ids: ticket_ids,
      assets:     assets,
    }
  end

end
