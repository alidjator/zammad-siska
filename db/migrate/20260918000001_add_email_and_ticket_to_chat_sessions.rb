# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 5 -- Item No. 5 (Live Chat Enhancement, Auto-Create Ticket). See
# docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.1. `email` holds the
# customer's email captured by the mandatory pre-chat form (Section
# 5.1.1/5.1.2) before a Chat::Session is even allowed to reach
# `waiting` state. `ticket_id` links back to the Ticket auto-created
# when an agent accepts the chat (Section 5.1.3) -- a real column with
# an index, not tucked into `preferences` like `participants`/`url`,
# because this relationship is expected to be queried for reporting
# (e.g. "how many chat sessions became tickets").
class AddEmailAndTicketToChatSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_sessions, :email, :string, limit: 250, null: true
    add_column :chat_sessions, :ticket_id, :integer, null: true
    add_index :chat_sessions, [:ticket_id]
    add_foreign_key :chat_sessions, :tickets
  end
end
