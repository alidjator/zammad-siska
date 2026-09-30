# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/team_kpi',         to: 'team_kpi#show',    via: :get
  match api_path + '/team_kpi/trend',   to: 'team_kpi#trend',   via: :get
  match api_path + '/team_kpi/heatmap', to: 'team_kpi#heatmap', via: :get
  match api_path + '/team_kpi/agents',  to: 'team_kpi#agents',  via: :get
  match api_path + '/team_kpi/export',  to: 'team_kpi#export',  via: :get
  match api_path + '/team_kpi/filter_options', to: 'team_kpi#filter_options', via: :get
  match api_path + '/team_kpi/tickets', to: 'team_kpi#tickets', via: :get
  match api_path + '/team_kpi/agent_options', to: 'team_kpi#agent_options', via: :get
end
