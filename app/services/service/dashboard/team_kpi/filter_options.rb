# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Options + ticket counts for the "KPI Tim" filter bar (Prioritas, Kanal,
# Kategori -- docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 18). Counts are the
# tickets created in the selected period within the user's groups and the
# chosen group filter only; the other dimension filters are deliberately
# ignored, so every option shows its full size and the lists never shrink
# while the user is picking.
class Service::Dashboard::TeamKpi::FilterOptions
  CHANNEL_LABELS = {
    'email'                     => 'Email',
    'web'                       => 'Web',
    'phone'                     => 'Phone',
    'sms'                       => 'SMS',
    'chat'                      => 'Chat',
    'telegram personal-message' => 'Telegram',
    'whatsapp message'          => 'WhatsApp',
    'note'                      => 'Catatan',
  }.freeze

  # always offered, even with 0 tickets in the period
  BASE_CHANNELS = %w[email web phone sms chat].freeze

  def self.call(...)
    new(...).call
  end

  def initialize(window_days: nil, user: nil, filters: {})
    window_days = Service::Dashboard::TeamKpi.window_days(window_days)
    group_only  = (filters || {}).to_h.symbolize_keys.slice(:group_ids)
    @scope = Service::Dashboard::TeamKpi::Scope.new(user: user, filters: group_only)
    @range = Service::Dashboard::TeamKpi::Scope.window_range(window_days)
  end

  def call
    { priorities: priorities, channels: channels, categories: categories }
  end

  private

  def tickets
    @tickets ||= @scope.tickets.where(created_at: @range)
  end

  def priorities
    counts = tickets.group(:priority_id).count
    Ticket::Priority.where(active: true).order(:id).map { |p| { id: p.id, name: p.name, count: counts[p.id].to_i } }
  end

  def channels
    counts = tickets.group(:create_article_type_id).count
    types  = Ticket::Article::Type.where(id: counts.keys).or(Ticket::Article::Type.where(name: BASE_CHANNELS)).pluck(:id, :name)
    types.map { |id, name| { name: name, label: CHANNEL_LABELS[name] || name.capitalize, count: counts[id].to_i } }
      .sort_by { |c| [-c[:count], c[:label]] }
  end

  def categories
    counts  = tickets.group(:category).count
    options = ObjectManager::Attribute.get(object: 'Ticket', name: 'category')&.data_option&.dig(:options) || {}
    options.map { |value, label| { value: value, label: label, count: counts[value].to_i } }
  end
end
