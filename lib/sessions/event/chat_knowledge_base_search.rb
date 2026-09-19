# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 7 -- Widget Live Chat Bergaya Tab (Home / Messages / Help). See
# docs/DESIGN_WIDGET_HOME_MESSAGES_HELP.md Section 2.2/5.1.
#
# Proxy tipis ke `SearchKnowledgeBaseBackend` (mesin pencari yang SAMA
# dipakai `KnowledgeBase::SearchController`, TIDAK ADA logika
# visibilitas baru ditulis di sini) -- dipanggil lewat WebSocket
# (bukan REST) SUPAYA TIDAK perlu melonggarkan CORS
# `KnowledgeBase::SearchController` untuk SEMUA origin di luar sana.
# Widget yang ditempel di domain lain SUDAH SELALU terhubung lewat
# WebSocket ini untuk live chat, jalur yang SAMA dipakai ulang di sini
# -- bukan permukaan publik baru.
#
# `user: nil` di panggilan `search_backend.search` SENGAJA TIDAK diisi
# -- visitor widget SELALU anonim, `SearchKnowledgeBaseBackend`
# otomatis membatasi hasil ke scope `published` untuk kondisi ini
# (dikonfirmasi lewat `lib/search_knowledge_base_backend.rb`, BUKAN
# diasumsikan).
#
# payload
#
#   {
#     event: 'chat_knowledge_base_search',
#     data: {
#       query: 'kata kunci pencarian',
#     },
#   }
#
# return dikirim balik sebagai pesan ke peer

class Sessions::Event::ChatKnowledgeBaseSearch < Sessions::Event::Base

  database_connection_required

  # Cuma hasil tipe ANSWER (artikel) yang relevan untuk daftar
  # pencarian "Help" -- hasil tipe Category/KnowledgeBase (dari mesin
  # pencari yang sama) tidak berarti apa-apa buat visitor yang cuma
  # mau cari jawaban, disaring di sini bukan di backend pencarian
  # (yang memang dirancang generik untuk 3 tipe sekaligus).
  ANSWER_TYPE = 'KnowledgeBase::Answer::Translation'.freeze

  MAX_RESULTS = 10

  def run
    query = @payload['data']['query'].to_s.strip
    return empty_result if query.blank?

    knowledge_base = KnowledgeBase.active.first
    return empty_result if !knowledge_base

    search_backend = SearchKnowledgeBaseBackend.new(
      knowledge_base: knowledge_base,
      flavor:         :public,
      index:          ANSWER_TYPE,
      limit:          MAX_RESULTS,
    )

    result = search_backend.search(query, user: nil)

    {
      event: 'chat_knowledge_base_search',
      data:  { result: result.filter_map { |meta| answer_details(meta) } },
    }
  end

  private

  def empty_result
    { event: 'chat_knowledge_base_search', data: { result: [] } }
  end

  def answer_details(meta)
    translation = KnowledgeBase::Answer::Translation.find_by(id: meta[:id])
    return if !translation

    category_translation = translation.answer.category.translation_preferred(translation.kb_locale)
    locale                = translation.kb_locale.system_locale.locale

    # URL harus MUTLAK (bukan path relatif) -- widget ini dibuka di
    # domain PIHAK LAIN (docs/DESIGN_WIDGET_HOME_MESSAGES_HELP.md
    # Section 1 poin 5), path relatif akan salah resolve ke domain
    # widget itu sendiri, bukan ke server SISKA. Tidak ada `request`
    # object di sini (bukan controller) untuk dukungan domain KB
    # custom (`custom_path_if_needed`) -- disederhanakan dengan
    # `Setting.get('http_type')`/`fqdn`, pola yang SAMA dipakai
    # `Chat::Session#agent_user` (Fase 5) untuk kasus serupa.
    path = Rails.application.routes.url_helpers.help_answer_path(category_translation, translation, locale: locale)
    url  = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{path}"

    {
      id:    translation.id,
      title: meta.dig(:highlight, 'title')&.first || translation.title,
      body:  (meta.dig(:highlight, 'content.body')&.first || translation.content.body_text_only.truncate(140)),
      url:   url,
    }
  rescue => e
    Rails.logger.error "Live Chat Knowledge Base search -- gagal membangun detail untuk translation id #{meta[:id]}: #{e.message}"
    nil
  end

end
