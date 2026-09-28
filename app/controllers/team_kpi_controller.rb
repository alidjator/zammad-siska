# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'csv'

# Backend for the "KPI Tim" Dashboard tab (see docs/DESIGN_TEAM_KPI_DASHBOARD.md).
#
# Every action is limited to the tickets in groups the current user can
# read, and accepts the same optional filters:
#   days=N, group_ids=1,2, priority_ids=3, channels=email,chat,
#   categories=request,complaint, compare=auto|previous|yoy|none
class TeamKpiController < ApplicationController
  prepend_before_action :authentication_check
  before_action :require_agent
  before_action :require_report_access, only: :agents

  # GET /api/v1/team_kpi
  def show
    render json: Service::Dashboard::TeamKpi.call(window_days: params[:days], user: current_user, filters: filters, compare: params[:compare], include_agents: report_access?), status: :ok
  end

  # GET /api/v1/team_kpi/trend?metric=frt|csat|volume|resolution
  def trend
    render json: Service::Dashboard::TeamKpi::Trend.call(metric: params[:metric].presence || 'frt', window_days: params[:days], user: current_user, filters: filters, compare: params[:compare]), status: :ok
  rescue ArgumentError => e
    raise Exceptions::UnprocessableEntity, e.message
  end

  # GET /api/v1/team_kpi/heatmap
  def heatmap
    render json: Service::Dashboard::TeamKpi::Heatmap.call(window_days: params[:days], user: current_user, filters: filters), status: :ok
  end

  # GET /api/v1/team_kpi/agents
  # Shows colleagues' individual performance, so it needs report access
  # (Zammad's own Reporting permission) or admin -- plain agents see only
  # the team totals.
  def agents
    render json: Service::Dashboard::TeamKpi::Agents.call(window_days: params[:days], user: current_user, filters: filters, limit: params[:limit] || 50), status: :ok
  end

  # GET /api/v1/team_kpi/filter_options -- Prioritas/Kanal/Kategori options
  # with ticket counts for the period (only the group filter applies).
  def filter_options
    render json: Service::Dashboard::TeamKpi::FilterOptions.call(window_days: params[:days], user: current_user, filters: filters), status: :ok
  end

  # GET /api/v1/team_kpi/tickets?metric=frt|csat|resolution|reopen|escalated|breach
  # Drill-down of a card: the tickets behind its number, same scope and
  # filters. format=csv downloads up to TeamKpi::Tickets::MAX_EXPORT rows.
  def tickets
    csv    = params[:format] == 'csv'
    limit  = csv ? Service::Dashboard::TeamKpi::Tickets::MAX_EXPORT : (params[:limit] || 50)
    result = Service::Dashboard::TeamKpi::Tickets.call(metric: params[:metric], window_days: params[:days], user: current_user, filters: filters, limit: limit)
    return render(json: result, status: :ok) if !csv

    send_data(tickets_csv(result), filename: "kpi-tim-#{result[:metric]}-#{Time.zone.today.iso8601}.csv", type: 'text/csv; charset=utf-8', disposition: 'attachment')
  rescue ArgumentError => e
    raise Exceptions::UnprocessableEntity, e.message
  end

  # GET /api/v1/team_kpi/export -- .xlsx of the whole dashboard, same
  # filters. The per-agent sheet is only included with report/admin.
  def export
    result = Service::Dashboard::TeamKpi::Export.call(
      window_days: params[:days], user: current_user, filters: filters, compare: params[:compare],
      include_agents: report_access?
    )
    send_data(result[:content], filename: result[:filename], type: Service::Dashboard::TeamKpi::Export::CONTENT_TYPE, disposition: 'attachment')
  end

  private

  TICKETS_CSV_HEADER = ['Nomor', 'Judul', 'Grup', 'Agent', 'Dibuat', 'Closed', 'Tanggal metrik', 'Nilai'].freeze

  def tickets_csv(result)
    body = CSV.generate(headers: true, col_sep: ',') do |csv|
      csv << TICKETS_CSV_HEADER
      result[:tickets].each do |t|
        csv << [t[:number], t[:title], t[:group], t[:owner], t[:created_at], t[:close_at], t[:at], t[:value]]
      end
    end
    # BOM: Excel membaca UTF-8 (judul tiket berhuruf non-ASCII) dengan benar
    "\uFEFF#{body}"
  end

  def report_access?
    current_user.permissions?(%w[report admin])
  end

  def require_agent
    raise Exceptions::Forbidden if !current_user.permissions?('ticket.agent')
  end

  def require_report_access
    raise Exceptions::Forbidden if !report_access?
  end

  def filters
    params.permit(:group_ids, :priority_ids, :channels, :categories, group_ids: [], priority_ids: [], channels: [], categories: []).to_h
  end
end
