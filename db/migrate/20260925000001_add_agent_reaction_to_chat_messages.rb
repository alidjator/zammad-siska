# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# G3 (docs/COMPARISON_WIDGET_VS_AGENT.md, keputusan user: "perlu"): agent
# bisa memberi reaksi emoji ke pesan CUSTOMER, kebalikan dari
# `customer_reaction` (reaksi customer ke pesan agent). Satu reaksi per
# pesan, whitelist 5 emoji yang sama di `Sessions::Event::ChatSessionReaction`.
class AddAgentReactionToChatMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_messages, :agent_reaction, :string, limit: 16, null: true
  end
end
