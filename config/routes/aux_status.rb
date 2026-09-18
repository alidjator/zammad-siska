# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/aux_statuses', to: 'aux_statuses#index', via: :get
  match api_path + '/aux_status', to: 'aux_statuses#update', via: :put
  match api_path + '/aux_status/:user_id', to: 'aux_statuses#override', via: :put
end
