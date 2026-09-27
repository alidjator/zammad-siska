# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
