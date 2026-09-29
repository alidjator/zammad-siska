# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Incoming-ticket load per weekday x hour for the "KPI Tim" heatmap
# (docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 10), in the system timezone.
# Each cell is the total tickets created in that weekday/hour over the
# period, and the average per occurrence of that weekday -- so a 30-day
# window with 4 or 5 Mondays is still comparable to a 7-day one.
class Service::Dashboard::TeamKpi::Heatmap
  def self.call(...)
    new(...).call
  end

  def initialize(window_days: nil, user: nil, filters: {})
    @window_days = Service::Dashboard::TeamKpi.window_days(window_days)
    @scope       = Service::Dashboard::TeamKpi::Scope.new(user: user, filters: filters)
    @range       = Service::Dashboard::TeamKpi::Scope.window_range(@window_days)
  end

  def call
    totals = @scope.tickets
      .where(created_at: @range)
      .group(Arel.sql(dow_sql), Arel.sql(hour_sql))
      .pluck(Arel.sql(dow_sql), Arel.sql(hour_sql), Arel.sql('COUNT(*)'))
      .to_h { |dow, hour, count| [[dow.to_i, hour.to_i], count.to_i] }
    days = weekday_occurrences

    cells = (1..7).flat_map do |dow|
      (0..23).map do |hour|
        total = totals[[dow, hour]].to_i
        { dow: dow, hour: hour, total: total, avg_per_day: days[dow].zero? ? 0.0 : (total.to_f / days[dow]).round(1) }
      end
    end

    {
      timezone:    timezone,
      business_hours: business_hours,
      window_days: @window_days,
      period:      { from: @range.begin.iso8601, to: @range.end.iso8601 },
      weekdays:    days,
      max_avg:     cells.pluck(:avg_per_day).max,
      cells:       cells,
    }
  end

  private

  # Jam kerja untuk ringkasan "Di luar jam kerja" (Section 22.6): dari
  # kalender default SISKA (dipakai semua SLA), bukan ditulis di kode.
  # { calendar:, days: { dow ISO (1 = Senin) => [[jam mulai, jam selesai], ...] } } dalam jam
  # desimal; hari tidak aktif = []. Libur nasional tidak dipakai (pola per
  # jam dalam seminggu).
  DAY_KEYS = %w[mon tue wed thu fri sat sun].freeze

  def business_hours
    calendar = Calendar.find_by(default: true) || Calendar.first
    return nil if !calendar

    hours = calendar.business_hours || {}
    days = DAY_KEYS.each_with_index.to_h do |key, index|
      day = hours[key] || {}
      frames = day['active'] ? Array(day['timeframes']) : []
      [index + 1, frames.map { |from, to| [to_hours(from), to_hours(to)] }]
    end
    { calendar: calendar.name, days: days }
  end

  def to_hours(value)
    h, m = value.to_s.split(':').map(&:to_i)
    h + (m.to_f / 60)
  end

  def timezone
    @timezone ||= Setting.get('timezone_default').presence || 'UTC'
  end

  # created_at is timestamptz: AT TIME ZONE gives the local wall-clock time
  def local_created_at
    "(created_at AT TIME ZONE #{ActiveRecord::Base.connection.quote(timezone)})"
  end

  # ISO weekday: 1 = Monday .. 7 = Sunday
  def dow_sql
    "EXTRACT(ISODOW FROM #{local_created_at})"
  end

  def hour_sql
    "EXTRACT(HOUR FROM #{local_created_at})"
  end

  # How many times each ISO weekday occurs in the period.
  def weekday_occurrences
    first = @range.begin.in_time_zone(timezone).to_date
    last  = (@range.end - 1.second).in_time_zone(timezone).to_date
    counts = (1..7).index_with(0)
    (first..last).each { |date| counts[date.cwday] += 1 }
    counts
  end
end
