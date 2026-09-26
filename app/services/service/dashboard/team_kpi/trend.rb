# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Time series for the "KPI Tim" trend chart (docs/DESIGN_TEAM_KPI_DASHBOARD.md
# Section 10). One metric per call, bucketed by day (<= 30 days), week
# (<= 180 days) or month (longer), in the system timezone
# (Setting timezone_default), plus the comparison period's series aligned
# by bucket index (same rule as the summary: previous / yoy / none).
#
# Escalated rate has no trend: it is a real-time snapshot and past values
# are not stored anywhere (would need a periodic snapshot job).
class Service::Dashboard::TeamKpi::Trend
  METRICS = {
    'frt'        => { column: 'created_at',        agg: :median, value: 'EXTRACT(EPOCH FROM (first_response_at - created_at)) / 60' },
    'csat'       => { column: 'csat_submitted_at', agg: :avg,    value: 'csat_score' },
    'volume'     => { column: 'created_at',        agg: :count,  value: nil },
    'resolution' => { column: 'close_at',          agg: :median, value: 'EXTRACT(EPOCH FROM (close_at - created_at)) / 60' },
  }.freeze

  def self.call(...)
    new(...).call
  end

  def self.bucket_for(days)
    if days <= 30
      'day'
    elsif days <= 180
      'week'
    else
      'month'
    end
  end

  def initialize(metric:, window_days: nil, user: nil, filters: {}, compare: 'auto')
    raise ArgumentError, "unknown metric #{metric.inspect}" if !METRICS.key?(metric.to_s)

    @metric      = metric.to_s
    @window_days = Service::Dashboard::TeamKpi.window_days(window_days)
    @scope       = Service::Dashboard::TeamKpi::Scope.new(user: user, filters: filters)
    @range       = Service::Dashboard::TeamKpi::Scope.window_range(@window_days)
    @comparison  = Service::Dashboard::TeamKpi::Scope.comparison(@range, @window_days, mode: compare)
    @bucket      = self.class.bucket_for(@window_days)
  end

  def call
    {
      metric:      @metric,
      bucket:      @bucket,
      timezone:    timezone,
      window_days: @window_days,
      period:      { from: @range.begin.iso8601, to: @range.end.iso8601 },
      points:      series(@range),
      comparison:  comparison,
    }
  end

  private

  def comparison
    return nil if !@comparison

    range = @comparison[:range]
    { mode: @comparison[:mode], period: { from: range.begin.iso8601, to: range.end.iso8601 }, points: series(range) }
  end

  def timezone
    @timezone ||= Setting.get('timezone_default').presence || 'UTC'
  end

  def config
    METRICS[@metric]
  end

  # columns are timestamptz: AT TIME ZONE gives the local wall-clock time
  def local(column)
    "(#{column} AT TIME ZONE #{ActiveRecord::Base.connection.quote(timezone)})"
  end

  def series(range)
    bucket_sql = "date_trunc('#{@bucket}', #{local(config[:column])})"
    values = relation(range)
      .group(Arel.sql(bucket_sql))
      .pluck(Arel.sql(bucket_sql), Arel.sql(aggregate_sql), Arel.sql('COUNT(*)'))
      .to_h { |start, value, count| [start.to_date, [value, count]] }

    bucket_starts(range).map do |start|
      value, count = values[start]
      { bucket_start: start.iso8601, value: value.nil? ? nil : value.to_f.round(2), count: count.to_i }
    end
  end

  def relation(range)
    relation = @scope.tickets.where(config[:column] => range)
    case @metric
    when 'frt'
      relation.where.not(first_response_at: nil).where('first_response_at >= created_at')
    when 'csat'
      relation.where.not(csat_score: nil)
    when 'resolution'
      relation.where('close_at >= created_at')
    else
      relation
    end
  end

  def aggregate_sql
    case config[:agg]
    when :median then "percentile_cont(0.5) WITHIN GROUP (ORDER BY #{config[:value]})"
    when :avg    then "AVG(#{config[:value]})"
    else              'COUNT(*)'
    end
  end

  # Every bucket in the range, also the empty ones, so the chart has a
  # continuous x axis and both series line up by index.
  def bucket_starts(range)
    first = range.begin.in_time_zone(timezone).to_date
    last  = (range.end - 1.second).in_time_zone(timezone).to_date
    step, first = case @bucket
                  when 'week'  then [1.week, first.beginning_of_week]
                  when 'month' then [1.month, first.beginning_of_month]
                  else              [1.day, first]
                  end

    starts = []
    while first <= last
      starts << first
      first += step
    end
    starts
  end
end
