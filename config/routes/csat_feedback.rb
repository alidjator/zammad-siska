# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  # Public CSAT feedback link (see docs/DESIGN_FEEDBACK_RATING.md).
  # Deliberately NOT under api_path -- this is a plain HTML page opened
  # directly by a customer, not a JSON API endpoint.
  match '/feedback/:ticket_id',         to: 'feedback#show',   via: :get
  match '/feedback/:ticket_id/submit',  to: 'feedback#submit', via: :post
end
