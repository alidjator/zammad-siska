# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Time series for the "KPI Tim" trend chart (docs/DESIGN_TEAM_KPI_DASHBOARD.md
# Section 10). One metric per call, bucketed by day (<= 30 days), week
# (<= 180 days) or month (longer), in the system timezone
# (Setting timezone_default), plus the comparison period's series aligned
# by bucket index (same rule as the summary: previous / yoy / none).
#
# Escalated rate comes from the hourly snapshots (TeamKpi::Snapshot, Section
# 13): per bucket, sum(escalated) / sum(new + open) over the snapshot hours
# in it -- so its history only starts when the snapshot job started
# (`history_since`), and it is unavailable with priority/channel/category
# filters (snapshots are only split by group).
class Service::Dashboard::TeamKpi::Trend
  METRICS = {
    'frt'        => { column: 'created_at',        agg: :median, value: :frt_minutes }, # Scope.frt_minutes_sql (Setting, Section 22)
    'csat'       => { column: 'csat_submitted_at', agg: :avg,    value: 'csat_score' },
    'volume'     => { column: 'created_at',        agg: :count,  value: nil },
    'resolution' => { column: 'close_at',          agg: :median, value: 'EXTRACT(EPOCH FROM (close_at - created_at)) / 60' },
    'escalated'  => { column: 'captured_at',       agg: :snapshot_rate, value: nil },
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
    result = {
      metric:      @metric,
      bucket:      @bucket,
      timezone:    timezone,
      window_days: @window_days,
      period:      { from: @range.begin.iso8601, to: @range.end.iso8601 },
      points:      series(@range),
      comparison:  comparison,
    }
    return result if !snapshot?

    snapshot = Service::Dashboard::TeamKpi::Snapshot
    result.merge(history_since: snapshot.history_since&.iso8601, unavailable: snapshot.supported?(@scope) ? nil : 'filters')
  end

  private

  def comparison
    return nil if !@comparison

    range = @comparison[:range]
    { mode: @comparison[:mode], period: { from: range.begin.iso8601, to: range.end.iso8601 }, points: series(range, count: bucket_starts(@range).size) }
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

  # count: force the number of buckets -- the comparison period must line
  # up index by index with the current one, but a week/month grid over a
  # range of the same length can start mid-bucket and yield one more or
  # one less bucket (e.g. 90 days = 14 vs 13 weeks).
  def series(range, count: nil)
    bucket_sql = "date_trunc('#{@bucket}', #{local(config[:column])})"
    return snapshot_series(range, bucket_sql, count) if snapshot?

    values = relation(range)
      .group(Arel.sql(bucket_sql))
      .pluck(Arel.sql(bucket_sql), Arel.sql(aggregate_sql), Arel.sql('COUNT(*)'))
      .to_h { |start, value, count| [start.to_date, [value, count]] }

    starts = bucket_starts(range)
    starts = starts.first(count) + (starts.size...count).map { |i| advance(starts.first, i) } if count
    starts.map do |start|
      value, count = values[start]
      value = 0 if value.nil? && config[:agg] == :count # no tickets = 0, not "no data"
      { bucket_start: start.iso8601, value: value.nil? ? nil : value.to_f.round(2), count: count.to_i }
    end
  end

  def snapshot?
    config[:agg] == :snapshot_rate
  end

  # Rate per bucket over the snapshot hours in it; buckets without any
  # snapshot hour are null (no data), hours with no ticket in scope are 0.
  def snapshot_series(range, bucket_sql, count)
    snapshot = Service::Dashboard::TeamKpi::Snapshot
    supported = snapshot.supported?(@scope)
    hours = TeamKpiSnapshot.markers.where(captured_at: range)
      .group(Arel.sql(bucket_sql)).pluck(Arel.sql(bucket_sql), Arel.sql('COUNT(*)'))
      .to_h { |start, n| [start.to_date, n.to_i] }
    sums = snapshot.rows_in_scope(@scope).where(captured_at: range)
      .group(Arel.sql(bucket_sql))
      .pluck(Arel.sql(bucket_sql), Arel.sql('SUM(ticket_escalated)'), Arel.sql('SUM(ticket_new + ticket_open)'))
      .to_h { |start, esc, denom| [start.to_date, [esc.to_i, denom.to_i]] }

    starts = bucket_starts(range)
    starts = starts.first(count) + (starts.size...count).map { |i| advance(starts.first, i) } if count
    starts.map do |start|
      n = hours[start].to_i
      esc, denom = sums[start]
      value = if !supported || n.zero?
                nil
              elsif denom.to_i.zero?
                0.0
              else
                (esc.to_f / denom * 100).round(2)
              end
      { bucket_start: start.iso8601, value: value, count: supported ? n : 0 }
    end
  end

  def relation(range)
    return @scope.frt_tickets(range) if @metric == 'frt'

    relation = @scope.tickets.where(config[:column] => range)
    case @metric
    when 'csat'
      relation.where.not(csat_score: nil)
    when 'resolution'
      relation.where('close_at >= created_at')
    else
      relation
    end
  end

  def value_sql
    config[:value] == :frt_minutes ? Service::Dashboard::TeamKpi::Scope.frt_minutes_sql : config[:value]
  end

  def aggregate_sql
    case config[:agg]
    when :median then "percentile_cont(0.5) WITHIN GROUP (ORDER BY #{value_sql})"
    when :avg    then "AVG(#{value_sql})"
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

  def advance(date, buckets)
    case @bucket
    when 'week'  then date + buckets.weeks
    when 'month' then date + buckets.months
    else              date + buckets.days
    end
  end
end
