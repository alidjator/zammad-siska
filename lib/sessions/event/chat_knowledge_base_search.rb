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
# Atas permintaan user (follow-up): tab Help SEKARANG menampilkan
# daftar artikel bahkan TANPA mengetik apa pun (5 artikel TERBARU,
# bukan kosong menunggu pencarian) + dukungan "load more" lewat
# scroll (bukan tombol/nomor halaman) -- `query` kosong berarti
# "jelajahi", `query` terisi berarti "filter/cari". `offset` dipakai
# KEDUA mode utk pagination scroll yang sama.
#
# payload
#
#   {
#     event: 'chat_knowledge_base_search',
#     data: {
#       query: 'kata kunci pencarian, boleh kosong utk jelajahi',
#       offset: 0, # kelipatan PAGE_SIZE, dari state widget
#     },
#   }
#
# return dikirim balik sebagai pesan ke peer
#
#   {
#     event: 'chat_knowledge_base_search',
#     data: {
#       result: [ { id:, title:, body:, url: }, ... ], # <= PAGE_SIZE item
#       has_more: true/false, # true -> widget boleh minta offset berikutnya
#       offset: 0, # digemakan balik, dipakai widget cegah race condition
#     },
#   }

class Sessions::Event::ChatKnowledgeBaseSearch < Sessions::Event::Base

  database_connection_required

  # Cuma hasil tipe ANSWER (artikel) yang relevan untuk daftar
  # pencarian "Help" -- hasil tipe Category/KnowledgeBase (dari mesin
  # pencari yang sama) tidak berarti apa-apa buat visitor yang cuma
  # mau cari jawaban, disaring di sini bukan di backend pencarian
  # (yang memang dirancang generik untuk 3 tipe sekaligus).
  ANSWER_TYPE = 'KnowledgeBase::Answer::Translation'.freeze

  PAGE_SIZE = 5

  def run
    query  = @payload['data']['query'].to_s.strip
    offset = @payload['data']['offset'].to_i
    offset = 0 if offset.negative?

    knowledge_base = KnowledgeBase.active.first
    return empty_result if !knowledge_base

    metas, has_more = if query.blank?
                        recent_metas(knowledge_base, offset)
                      else
                        searched_metas(knowledge_base, query, offset)
                      end

    {
      event: 'chat_knowledge_base_search',
      data:  {
        result:   metas.filter_map { |meta| answer_details(meta) },
        has_more: has_more,
        offset:   offset,
        # Digemakan balik supaya widget bisa membuang respons BASI
        # (mis. hasil query lama yang baru sampai SETELAH user sudah
        # ganti ketikan) -- dibandingkan ke query TERKINI di sisi
        # widget sebelum dipakai render.
        query:    query,
      },
    }
  end

  private

  def empty_result
    { event: 'chat_knowledge_base_search', data: { result: [], has_more: false, offset: 0 } }
  end

  # Mode "jelajahi" (query kosong) -- 5 artikel PUBLISHED terbaru
  # (`sorted_by_published`, scope resmi model `KnowledgeBase::Answer`,
  # BUKAN query baru), lintas SEMUA kategori dalam KB aktif. Sengaja
  # TIDAK memfilter permission per-kategori tambahan -- jalur
  # pencarian (`searched_metas` di bawah, lewat
  # `SearchKnowledgeBaseBackend`) juga TIDAK melakukan itu utk
  # flavor `:public`/anonim (dicek ke `translation_ids_for_answers`),
  # jadi mode jelajahi ini SENGAJA disamakan visibilitasnya persis
  # dgn mode pencarian, bukan lebih longgar/ketat sepihak.
  def recent_metas(knowledge_base, offset)
    answers = KnowledgeBase::Answer
      .joins(:category)
      .where(knowledge_base_categories: { knowledge_base_id: knowledge_base.id })
      .sorted_by_published
      .offset(offset)
      .limit(PAGE_SIZE + 1)
      .to_a

    has_more = answers.size > PAGE_SIZE
    metas    = answers.first(PAGE_SIZE).filter_map { |answer| answer.translations.first }.map { |translation| { id: translation.id } }

    [metas, has_more]
  end

  # Mode "cari" (query terisi) -- proxy ke `SearchKnowledgeBaseBackend`
  # spt sebelumnya, SEKARANG dgn pagination (`offset`/`limit`) supaya
  # bisa "load more" lewat scroll, bukan cuma 1 halaman tetap.
  def searched_metas(knowledge_base, query, offset)
    search_backend = SearchKnowledgeBaseBackend.new(
      knowledge_base: knowledge_base,
      flavor:         :public,
      index:          ANSWER_TYPE,
      limit:          PAGE_SIZE + 1,
    )

    pagination = Struct.new(:offset, :limit).new(offset, PAGE_SIZE + 1)
    metas      = search_backend.search(query, user: nil, pagination: pagination)

    has_more = metas.size > PAGE_SIZE

    [metas.first(PAGE_SIZE), has_more]
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
