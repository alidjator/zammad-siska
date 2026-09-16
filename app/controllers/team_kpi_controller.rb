# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Backend for the "KPI Tim" Dashboard tab (see docs/DESIGN_TEAM_KPI_DASHBOARD.md).
class TeamKpiController < ApplicationController
  prepend_before_action :authentication_check

  # GET /api/v1/team_kpi
  def show
    raise Exceptions::Forbidden if !current_user.permissions?('ticket.agent')

    render json: Service::Dashboard::TeamKpi.call, status: :ok
  end
end
