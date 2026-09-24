# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Atas permintaan user: reaksi emoji pada bubble ala WhatsApp (mockup
# "Reaksi emoji bubble"). Fase ini HANYA customer (widget) yg memberi
# reaksi ke pesan AGENT, satu reaksi per pesan -- cukup satu kolom string
# nullable (`nil` = tanpa reaksi). Emoji dibatasi whitelist 5 buah di
# `Sessions::Event::ChatSessionReaction`. Tampilan reaksi di panel agent
# menyusul di fase berikutnya (lihat docs/TASKLIST_SISKA.md).
class AddCustomerReactionToChatMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_messages, :customer_reaction, :string, limit: 16, null: true
  end
end
