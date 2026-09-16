# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Backend for the "KPI Tim" Dashboard tab (see docs/DESIGN_TEAM_KPI_DASHBOARD.md).
class TeamKpiController < ApplicationController
  prepend_before_action :authentication_check

  # GET /api/v1/team_kpi?days=N
  def show
    raise Exceptions::Forbidden if !current_user.permissions?('ticket.agent')

    days = params[:days].presence || Service::Dashboard::TeamKpi::DEFAULT_WINDOW_DAYS
    render json: Service::Dashboard::TeamKpi.call(window_days: days), status: :ok
  end
end
