# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Atas permintaan user ("saya mau menambahkan kategori ini pada halaman
# messages, sejalan dengan inputan name, email"): field Category ketiga
# di form Prechat (mockup https://claude.ai/artifact/NK8sD4jGGDbxq3mquCx9jL),
# wajib diisi sama seperti name/email. Ditaruh sebagai kolom NYATA (pola
# sama dgn `email`/`ticket_id`, lihat 20260918000001) -- BUKAN
# `preferences` -- karena nilainya perlu disalurkan ke `Ticket#category`
# (custom field Ticket yang SUDAH ADA, lihat `Chat::Session.category_options`
# di app/models/chat/session.rb) saat tiket auto-created, dan berguna utk
# pelaporan (sama alasan `ticket_id` jadi kolom, bukan preferences).
class AddCategoryToChatSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_sessions, :category, :string, limit: 100, null: true
  end
end
