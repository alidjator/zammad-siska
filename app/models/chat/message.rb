# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Chat::Message < ApplicationModel
  include ChecksHtmlSanitized

  belongs_to :chat_session, class_name: 'Chat::Session'
  belongs_to :created_by, class_name: 'User', optional: true
  # Fitur tambahan "Reply ke Pesan Spesifik" --
  # docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.3.
  belongs_to :reply_to, class_name: 'Chat::Message', optional: true

  sanitized_html :content

  # Atas permintaan user (screenshot: kutipan reply ke pesan attachment
  # menampilkan literal "[attachment]", bukan nama filenya) -- `content`
  # utk pesan attachment SELALU literal string `'[attachment]'`
  # (lihat `chat_attachments_controller.rb`), nama file sungguhan
  # cuma tersimpan terpisah lewat `Store` (pola SAMA persis dgn
  # `Chat::Session.enrich_message_attributes`'s deteksi `filename`).
  # Dipakai di KEDUA titik yang menyusun kutipan reply --
  # `chat_session_message.rb` (broadcast real-time) DAN
  # `Chat::Session.enrich_message_attributes` (riwayat/reconnect) --
  # supaya keduanya konsisten tanpa duplikasi logika deteksi attachment.
  def display_content
    store = Store.list(object: 'Chat::Message', o_id: id).first
    return store.filename if store

    content
  end
end
