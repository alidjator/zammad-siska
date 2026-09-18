# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 5 -- Item No. 6 (Live Chat Enhancement, Attachment). See
# docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.2.1.
Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/chat_sessions/:session_id/attachments', to: 'chat_attachments#create', via: :post

end
