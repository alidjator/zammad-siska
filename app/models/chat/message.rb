# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Chat::Message < ApplicationModel
  include ChecksHtmlSanitized

  belongs_to :chat_session, class_name: 'Chat::Session'
  belongs_to :created_by, class_name: 'User', optional: true
  # Fitur tambahan "Reply ke Pesan Spesifik" --
  # docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.3.
  belongs_to :reply_to, class_name: 'Chat::Message', optional: true

  sanitized_html :content
end
