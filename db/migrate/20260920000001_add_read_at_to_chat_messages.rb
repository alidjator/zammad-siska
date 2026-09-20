# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Atas permintaan user: penanda "terkirim"/"sudah dibaca" ala WhatsApp
# pada widget customer (mockup `Messages.dc.html`). `read_at` cukup
# nullable timestamp sederhana -- `nil` berarti belum dibaca, terisi
# berarti waktu agent membaca pesan itu. Dipakai "read up to" (bulk,
# semua pesan customer yang belum terbaca ditandai sekaligus saat agent
# fokus ke jendela chat, bukan per-pesan granular) -- lihat
# `Sessions::Event::ChatSessionMessageRead`.
class AddReadAtToChatMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_messages, :read_at, :datetime, null: true
  end
end
