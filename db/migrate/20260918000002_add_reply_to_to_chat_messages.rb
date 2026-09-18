# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 5 -- fitur tambahan "Reply ke Pesan Spesifik (Seperti
# WhatsApp)". See docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.3.
# Real self-referencing FK (not a preferences/JSON column) -- this is a
# simple, well-defined 1-to-1 relationship (one message replies to
# exactly one other message), no need for JSON flexibility.
class AddReplyToToChatMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_messages, :reply_to_id, :integer, null: true
    add_foreign_key :chat_messages, :chat_messages, column: :reply_to_id
  end
end
