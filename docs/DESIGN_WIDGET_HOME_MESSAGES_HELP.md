# Desain Teknis — Widget Live Chat Bergaya Tab (Home / Messages / Help) — Fase 7

**Status:** Riset & desain rinci selesai. BELUM diimplementasikan.
**Bergantung pada:** Fase 5 (`docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md`) — widget `public/assets/chat/` (JS/CoffeeScript standalone, toolchain gulp terpisah) dipakai ulang & diperluas, BUKAN dibangun ulang dari nol.

---

## 1. Requirement dari User

> "saya mau, widget chat visitor dibuat meniru gaya gaya claude, ada home, message, help. help menggunakan data dari knowledge base, kamu riset kebutuhannya"

Diterjemahkan:
1. Widget live chat untuk VISITOR (bukan Fase 6 yang untuk user login) diberi 3 tab di bagian bawah: **Home**, **Messages**, **Help** — gaya widget dukungan ala Intercom/Drift/Claude.
2. **Messages** = fungsi chat yang SUDAH ADA (Fase 5), dipindah jadi salah satu tab, bukan diubah logikanya.
3. **Help** = FITUR BARU, menampilkan/mencari artikel Knowledge Base.
4. **Home** = tab BARU, disepakati (AskUserQuestion): sapaan singkat + 2 tombol pintasan ("Kirim Pesan" → buka tab Messages, "Cari Bantuan" → buka tab Help) — bukan versi kompleks dengan daftar artikel populer/promoted.
5. Widget ini akan ditempel di **domain LAIN** dari server SISKA (website resmi PT SIM/klien) — dikonfirmasi eksplisit lewat AskUserQuestion, BUKAN satu domain — jadi CORS (Section 3) adalah masalah NYATA, bukan teoretis.
6. Sekalian diperbaiki: celah CORS pada fitur attachment upload (Fase 5, sudah live) — akar masalah SAMA (endpoint anonim widget tanpa header CORS), disepakati diperbaiki bersamaan (AskUserQuestion).

---

## 2. Temuan Riset

### 2.1 Knowledge Base publik SUDAH ADA & cocok dipakai, tanpa logika visibilitas baru

`POST /api/v1/knowledge_bases/search` (`app/controllers/knowledge_base/search_controller.rb`) bisa diakses ANONIM (`prepend_before_action :authentication_check_only`, BUKAN `authenticate_and_authorize!` -- pola yang SAMA persis dipakai `ChatAttachmentsController` Fase 5). Backend pencarian (`SearchKnowledgeBaseBackend`) otomatis membatasi hasil ke scope `published` kalau `user` nil (visitor anonim) -- TIDAK PERNAH membocorkan draft/internal, tanpa perlu kode tambahan apa pun untuk itu.

Bentuk respons (`{result:, details:}`), tiap entri artikel:
```json
{
  "id": 123, "type": "KnowledgeBase::Answer::Translation",
  "url": "/help/en-us/kategori/nama-artikel",
  "title": "Judul <em>disorot</em>", "body": "cuplikan teks polos"
}
```
Parameter `url_type: 'public'` (default) menghasilkan URL yang bisa langsung dipakai visitor untuk buka artikel lengkap di `/help/...` (halaman KB publik yang SUDAH ADA, server-rendered, tidak perlu dibuat baru).

### 2.2 CORS -- masalah NYATA, bukan teoretis (dikonfirmasi user: widget akan ditempel di domain lain)

Endpoint di atas TIDAK mengirim header `Access-Control-Allow-Origin` untuk request ANONIM (`app/controllers/application_controller/sets_headers.rb#set_access_control_headers` cuma set CORS kalau auth type-nya token/basic -- kosong untuk anonim). Kalau widget di domain lain memanggil endpoint ini langsung lewat `fetch`/`$.ajax`, browser AKAN memblokir responsnya (preflight lolos, response asli diblokir).

**Solusi dipilih**: proxy pencarian KB lewat KONEKSI WEBSOCKET yang widget SUDAH SELALU punya untuk chat (bukan REST call baru) -- WebSocket tidak tunduk pada CORS fetch/XHR yang sama, dan pola ini konsisten dengan SEMUA komunikasi widget lain (`chat_session_init`, dst. sudah lewat WebSocket). Ini MENGHINDARI perlu melonggarkan CORS controller KB sama sekali (tidak memperluas permukaan anonim publik yang sudah ada) -- alternatif (menambah header CORS ala `FormController` ke `KnowledgeBase::SearchController`) SENGAJA TIDAK dipilih karena akan melonggarkan endpoint itu untuk SEMUA origin, bukan cuma widget kita.

### 2.3 Ditemukan sekaligus: celah CORS YANG SAMA di fitur attachment upload (Fase 5, sudah live)

`ChatAttachmentsController` (Fase 5, Section 5.2.1) memakai pola anonim yang SAMA (`authentication_check_only`) TAPI dipanggil lewat `$.ajax`/`XMLHttpRequest` LANGSUNG dari browser widget (`apiBaseUrl()` di `chat.coffee`/`chat-no-jquery.coffee`), BUKAN lewat WebSocket -- ini SUDAH BUTUH CORS sejak awal, TAPI belum pernah ditambahkan, dan belum pernah diuji di domain yang GENUINELY berbeda (semua pengujian sejauh ini, termasuk punya user sendiri, kebetulan satu domain dengan server SISKA lewat static file serving). Kalau dibiarkan, upload attachment akan GAGAL DIAM-DIAM begitu widget ditempel di domain asli PT SIM.

**Diperbaiki (Section 5.4)**: `ChatAttachmentsController` diberi header CORS eksplisit ala `FormController` (`app/controllers/form_controller.rb`, satu-satunya preseden native "publik + anonim + lintas-domain" di codebase ini) -- KHUSUS controller ini (bukan melonggarkan `KnowledgeBase::SearchController`), karena upload FILE secara arsitektur harus tetap lewat REST (bukan WebSocket, tidak cocok untuk payload biner besar).

### 2.4 Struktur widget SAAT INI: tidak ada state machine terpusat, tapi cukup rapi untuk diperluas

Tidak ada satu method `render()` yang mengatur SEMUA tampilan -- tiap event WebSocket independen menimpa salah satu dari 2 slot tetap: `.zammad-chat-modal` (layar status/form, ditimpa penuh) dan `.zammad-chat-body` (log pesan, ditambah terus). Konsekuensinya BAGUS untuk rencana ini: seluruh markup chat yang SUDAH ADA (`.zammad-chat-modal`, `.zammad-chat-body`, `.zammad-chat-controls`) bisa DIBUNGKUS APA ADANYA jadi "isi tab Messages" TANPA mengubah selector/logic manapun yang sudah ada (`@el.find('.zammad-chat-modal')` dst. tetap jalan, tidak peduli ada wrapper baru di atasnya).

Tidak ada sistem ikon sprite (semua SVG inline per-template) dan TIDAK ADA badge unread berupa angka (cuma class CSS highlight per-bubble berdasarkan `document.hidden`) -- badge angka di tab "Messages" adalah kerja BARU murni kalau diinginkan (lihat Section 6, opsional/nice-to-have, tidak diminta eksplisit).

---

## 3. Arsitektur

```
Widget dibuka (embed di website PT SIM, domain BEDA dari server SISKA)
        |
        v
Bottom tab bar BARU (Home | Messages | Help), SELALU terlihat
apa pun tab aktif -- markup baru, sibling dari .zammad-chat-controls
        |
        +-- [Home] (default saat pertama dibuka)
        |     sapaan singkat + tombol "Kirim Pesan" / "Cari Bantuan"
        |     (murni switch tab, tidak ada state/network)
        |
        +-- [Messages] (fungsi Fase 5 yang SUDAH ADA, TIDAK DIUBAH)
        |     .zammad-chat-modal + .zammad-chat-body + .zammad-chat-controls
        |     dibungkus APA ADANYA jadi "isi tab ini" -- prechat form,
        |     percakapan, attachment, reply-to: SEMUA jalan seperti biasa
        |
        +-- [Help] (BARU)
              kotak pencarian -> kirim event WebSocket BARU
              (mis. chat_knowledge_base_search) -> backend proxy ke
              SearchKnowledgeBaseBackend (Section 2.1, TIDAK ADA logika
              visibilitas baru) -> hasil (judul+cuplikan+url) dirender
              sebagai daftar -> klik hasil = <a target="_blank"> ke
              /help/... (halaman KB publik yang SUDAH ADA)
```

---

## 4. Perubahan Frontend (widget, `public/assets/chat/`)

Dikerjakan di **KEDUA** file (`chat.coffee` jQuery + `chat-no-jquery.coffee` vanilla) -- pola risiko yang SAMA sudah berulang sejak Fase 5, bukan sesuatu yang baru.

### 4.1 View baru

- `views/tabbar.eco` -- 3 tombol (Home/Messages/Help), masing-masing ikon SVG inline (ikuti konvensi widget yang sudah ada, BUKAN bikin sistem sprite baru) + label teks.
- `views/home.eco` -- sapaan + 2 tombol (`.js-tab-messages`, `.js-tab-help` -- reuse mekanisme switch tab, BUKAN event baru).
- `views/help.eco` -- kotak pencarian (`<input class="js-kb-search">`) + `<ul class="zammad-chat-kb-results">` kosong (diisi JS setelah hasil pencarian datang).
- `views/kb_result.eco` -- SATU baris hasil pencarian (judul + cuplikan + link `/help/...`, `target="_blank"` supaya visitor tidak meninggalkan widget/percakapan yang sedang berjalan).

### 4.2 `views/chat.eco` -- restrukturisasi MINIMAL (bukan rombak)

Konten yang SUDAH ADA (`.zammad-chat-modal`, `.zammad-chat-body`, `.zammad-chat-reply-indicator`, `.zammad-chat-controls`) dibungkus SATU div baru `<div class="zammad-chat-tab-body zammad-chat-tab-body--messages">`, ditambah 2 div SEJENIS untuk Home & Help (kosong, diisi lewat `@view()` seperti pola yang sudah ada di seluruh widget). Bottom tab bar (`@view('tabbar')`) ditambah sebagai sibling BARU, di bawah ketiga tab-body itu.

### 4.3 Logika switch tab (method baru, `switchTab: (tabName) =>`)

Toggle class `is-active` pada tab-body yang sesuai + tombol tab bar yang sesuai -- POLA YANG SAMA seperti toggle `zammad-chat-is-hidden` yang sudah dipakai di banyak tempat lain di widget ini, bukan mekanisme baru. Default tab saat widget pertama dibuka: **Home** (bukan langsung Messages) -- kalau ada sesi chat yang SEDANG BERJALAN (reconnect), langsung ke tab **Messages** supaya visitor tidak kehilangan percakapannya sendiri.

### 4.4 Penyesuaian animasi buka/tutup

`open()`/`close()` (kedua varian) memakai `@el.height()`/`.zammad-chat-header outerHeight()` untuk hitung animasi slide -- dengan tab bar baru menambah tinggi total, perhitungan ini perlu ikut menghitung tinggi tab bar (`.outerHeight()`-nya), SATU penyesuaian kecil di titik yang SAMA dengan fix `restingBottom` sebelumnya (bukan logic baru, cuma operand tambahan di rumus yang sudah ada).

### 4.5 Tab Help -- pencarian KB

`onKbSearchInput` (debounced, pola timer yang sama dengan `showWritingLoader`'s delay mechanism yang sudah ada) mengirim:
```coffee
App.WebSocket... # bukan App.WebSocket (itu punya app utama) -- widget pakai @send() sendiri
@send('chat_knowledge_base_search', { query: value })
```
Balasan ditangani di `onWebSocketMessage` (Section 2.4/2.5 riset -- titik hook SUDAH diketahui, `chat.coffee:1033`/`chat-no-jquery.coffee:1020`), render tiap hasil lewat `@view('kb_result')`.

### 4.6 CSS (`chat.scss`, +1 bagian baru di akhir file mengikuti pola comment-banner yang sudah ada)

Style untuk tab bar (flex row, 3 tombol sama lebar, ikon+label), tab-body show/hide, Home tab (sapaan+tombol), Help tab (kotak cari+daftar hasil). TIDAK menyentuh style yang sudah ada untuk Messages (chat bubble, dst.).

---

## 5. Perubahan Backend

### 5.1 Event WebSocket baru: `Sessions::Event::ChatKnowledgeBaseSearch`

File baru `lib/sessions/event/chat_knowledge_base_search.rb`, pola SAMA persis dengan event chat lain (`< Sessions::Event::ChatBase` atau `< Sessions::Event::Base` -- TIDAK butuh sesi chat yang sedang berjalan, jadi kemungkinan besar `< Sessions::Event::Base` langsung, bukan `ChatBase` yang mewajibkan `Setting.get('chat')`). TIDAK perlu tahu `chat_id`/sesi apa pun -- pencarian KB independen dari status chat.

```ruby
def run
  return super if super

  query = @payload['data']['query'].to_s.strip
  return { event: 'chat_knowledge_base_search', data: { result: [] } } if query.blank?

  # current_user SENGAJA tidak diisi (anonim) -- SearchKnowledgeBaseBackend
  # otomatis membatasi ke scope `published` untuk kondisi ini (Section 2.1),
  # TIDAK ADA logika visibilitas baru ditulis di sini.
  details = SearchKnowledgeBaseBackend.new(...).search(query, ...)

  {
    event: 'chat_knowledge_base_search',
    data:  { result: details },
  }
end
```
(detail parameter method `SearchKnowledgeBaseBackend` disesuaikan saat implementasi, mengikuti signature yang SUDAH ADA di `KnowledgeBase::SearchController` -- bukan menebak.)

**Tidak perlu deploy ke DUA container terpisah secara berbeda dari event chat lain** -- tetap ikut disiplin yang SUDAH ditetapkan sejak Fase 5 (entry 95): setiap file baru di `lib/sessions/event/` di-deploy ke KEDUA container (`zammad-app` & `zammad-websocket`).

### 5.2 Rate limiting / abuse (dipertimbangkan, keputusan MENUNGGU user)

Karena ini endpoint pencarian ANONIM baru (walau lewat WebSocket, bukan REST), perlu dipikirkan apakah butuh pembatasan (mis. jeda antar-pencarian per koneksi, atau memakai mekanisme rate-limit NATIVE Zammad yang mungkin sudah ada untuk event WebSocket lain) supaya tidak disalahgunakan untuk membebani Elasticsearch/DB (relevan mengingat disk & ES sempat bermasalah, Fase 6 entry 110). Perlu ditelusuri saat implementasi apakah `Sessions::Event::Base` sudah py mekanisme generik untuk ini, atau perlu ditambahkan.

### 5.3 Tidak ada Setting/migration baru untuk fitur KB search ini

Visibilitas SUDAH otomatis benar (Section 2.1), tidak ada kolom/tabel baru.

### 5.4 Perbaikan CORS `ChatAttachmentsController` (Section 2.3)

Ditambahkan (meniru `app/controllers/form_controller.rb`):
```ruby
class ChatAttachmentsController < ApplicationController
  skip_before_action :verify_csrf_token
  prepend_before_action :authentication_check_only
  before_action :cors_preflight_check          # BARU
  after_action  :set_access_control_headers_execute  # BARU -- unconditional, beda dari default yang cuma jalan untuk token/basic auth
  ...
```
Ini SATU-SATUNYA controller yang diberi override ini -- `KnowledgeBase::SearchController` SENGAJA TIDAK disentuh (Section 2.2, dihindari lewat pendekatan WebSocket).

---

## 6. Yang SENGAJA Tidak Diikutkan (Sesuai Keputusan Rincian)

| Fitur ala Intercom | Ikut? | Alasan |
|---|---|---|
| Tab Home: sapaan + 2 tombol pintasan | Ya | Keputusan eksplisit user (AskUserQuestion) |
| Tab Home: daftar artikel populer/promoted | **Tidak** | Opsi yang TIDAK dipilih user -- butuh konsep "artikel promoted tampil di widget" yang belum ada, perubahan besar terpisah kalau nanti diminta |
| Tab Messages: fungsi chat penuh (attachment, reply-to, dst.) | Ya, APA ADANYA | Sudah ada sejak Fase 5, tidak diubah logikanya |
| Tab Help: cari + baca cuplikan + link ke artikel lengkap | Ya | Inti requirement |
| Tab Help: baca artikel LENGKAP di dalam widget (bukan buka tab baru) | **Tidak dirancang** | Perlu render rich-text KB di dalam widget kecil -- kerja tambahan signifikan, `target="_blank"` ke halaman `/help/...` yang sudah ada jauh lebih murah & sudah cukup untuk requirement awal |
| Badge angka unread di tab Messages | **Tidak dirancang** | Tidak diminta eksplisit; ditemukan saat riset bahwa widget ini TIDAK PUNYA mekanisme badge angka sama sekali (Section 2.4) -- kerja baru murni kalau nanti diminta |

---

## 7. Rencana Pengujian & Rollout

1. Implementasi (frontend 2 varian + backend event + CORS fix).
2. **Pengujian CORS harus GENUINELY lintas-domain** (beda dari kesalahan pengujian Fase 5 sebelumnya yang tanpa sadar selalu same-origin) -- perlu disiapkan test page di domain/port yang BERBEDA dari `helpdesk.satu.solutions` (mis. lewat `--host-resolver-rules` Playwright/Chrome ke domain palsu KEDUA, bukan cuma satu seperti sebelumnya) supaya benar-benar menguji comportment lintas-origin, bukan kebetulan lolos karena same-origin lagi.
3. Verifikasi Playwright (WAJIB, sesuai keputusan proses terbaru): buka tab Home → klik "Cari Bantuan" → pindah ke tab Help → ketik query → hasil KB muncul → klik hasil → tab baru terbuka ke `/help/...`. Buka tab Home → klik "Kirim Pesan" → pindah ke tab Messages → chat berjalan seperti biasa (regression check Fase 5, termasuk attachment upload BENAR-BENAR lintas-domain kali ini).
4. Build gulp bersih untuk KEDUA varian (`chat.js`/`chat.min.js`/`chat-no-jquery.js`/`chat-no-jquery.min.js`/`chat.css`), dikonfirmasi lewat `grep` ke compiled bundle seperti pola yang sudah mapan sepanjang Fase 5.

---

## 8. Hasil Implementasi & Pengujian (Revisi 1)

Implementasi selesai mengikuti desain di atas TANPA perubahan arsitektur -- catatan di bawah murni temuan/perbaikan kecil dari proses implementasi+pengujian nyata.

1. **CORS `ChatAttachmentsController`**: ternyata `before_action :cors_preflight_check` SUDAH otomatis ter-include lewat `ApplicationController::SetsHeaders` (di-cek ke kode dulu, bukan diasumsikan) -- jadi implementasi Section 5.4 disederhanakan jadi SATU baris (`after_action :set_access_control_headers_execute`), bukan dua seperti draf awal.
2. **Bug `super` di `ChatKnowledgeBaseSearch#run`**: draf Section 5.1 memakai `return super if super` (pola `ChatBase`) -- salah untuk subclass `Sessions::Event::Base` langsung (tidak ada `run` di superclass-nya), error `super: no superclass method 'run'`. Dikonfirmasi lewat `Sessions::Event::Maintenance` sebagai referensi pola yang benar, baris dihapus.
3. **Restart container `zammad-websocket` diperlukan** setelah file event baru ditambahkan -- proses Ruby long-running ini tidak auto-reload constant baru meski file sudah ada di filesystem (`docker cp` saja tidak cukup). Ditemukan lewat error `NameError: uninitialized constant` saat pengujian browser sungguhan, bukan saat verifikasi backend langsung (`Sessions::Event.run` dari dalam container YANG SAMA tempat proses itu berjalan tidak mengalami masalah ini).
4. **Pengujian genuinely lintas-domain**: dibangun lewat server HTTP lokal (`http://client-website-fake.test:8199`, hostname di-map ke `127.0.0.1` via Chrome `--host-resolver-rules`) yang memuat widget LANGSUNG dari `https://helpdesk.satu.solutions` sungguhan -- BUKAN memetakan domain SISKA sendiri ke localhost seperti kesalahan skrip pengujian Fase 5 sebelumnya. Hasil: Home/Messages/Help tab switching benar, pencarian KB (highlight + URL absolut + `target="_blank"`) benar sampai artikel asli termuat di tab baru, DAN upload attachment lintas-domain BERHASIL (bukti nyata celah CORS Fase 5 sudah tertutup) -- zero console/JS error di sisi visitor.
5. **30 artikel KB yang sudah ada semuanya belum di-publish** (internal-only) -- tab Help akan kosong bagi visitor sungguhan sampai tim konten mem-publish artikel apa pun. 1 artikel test dibuat untuk verifikasi (id 76, "Test Fase 7 - Cara Reset Password") dan SENGAJA dibiarkan sebagai fixture pengujian lanjutan.

Detail lengkap tiap temuan ada di `docs/ACTIVITY_LOG_SISKA.md` entri 115.

---

## 9. Revisi 2 — Struktur "Tombol Bulat Mengambang" (atas permintaan user)

User memberi 2 screenshot referensi (gaya Intercom/Claude) dan koreksi eksplisit: struktur Revisi 1 (pil header + tab bar SELALU terlihat mengambang sejak halaman dimuat, melebar ke atas saat diklik) BUKAN yang dimaksud -- yang diminta: **saat halaman dimuat, HANYA ada satu tombol bulat mengambang; klik tombol itu baru memunculkan panel penuh (header+tab body+tab bar)**.

**Perubahan** (Section 3/4 di atas tetap berlaku untuk ISI ketiga tab -- revisi ini HANYA mengubah bagaimana panel itu sendiri tampil/tersembunyi):
- View baru `views/launcher.eco` -- tombol bulat, dirender TERPISAH dari panel (`@el`/`this.el` di kode TETAP `.zammad-chat` seperti Revisi 1, tidak diubah maknanya sama sekali -- ditambah referensi baru `@launcherEl`/`this.launcherEl`).
- Panel `.zammad-chat` SELALU tersembunyi total saat tertutup (`opacity:0; pointer-events:none`), bukan menyisakan header seperti Revisi 1. Header di dalam panel jadi HANYA tampil saat panel terbuka -- ikon toggle ganda (chevron+silang) disederhanakan jadi SATU ikon silang statis; tombol bulat sekarang yang berperan sebagai toggle utama (ikon bubble<->chevron mengikuti state).
- Animasi buka/tutup LAMA (hitung tinggi panel dikurangi header+tab bar, geser posisi `bottom`/`transform` manual) DIHAPUS TOTAL, diganti transisi CSS murni (opacity+transform, `transitionend` untuk callback) -- disatukan polanya di KEDUA varian widget.

**Bug ditemukan & diperbaiki saat verifikasi sendiri**: tombol silang penutup di header awalnya dipasang di elemen pembungkus yang collapse jadi 0x0 (kombinasi `float`+anak `position:absolute`, tidak ada anak yang menyumbang ukuran) -- Playwright melaporkan "not visible" walau CSS `visibility:visible`, dikonfirmasi lewat `getBoundingClientRect()`. Dipindah ke elemen anak (`.zammad-chat-header-icon`) yang benar-benar berukuran.

**Diverifikasi Playwright** (genuinely lintas-domain, pola sama Section 8): tertutup = cuma tombol bulat (opacity/pointer-events dicek programatik); klik = panel muncul, ikon berubah, tab default Home; tutup lewat tombol ATAU silang header sama-sama berhasil; regresi PENUH (KB search + upload attachment lintas-domain) diulang & lolos tanpa error pada percobaan pertama; tampilan mobile (390x800) dicek terpisah -- fullscreen saat terbuka, tombol tetap terlihat sebagai penutup.

Detail lengkap di `docs/ACTIVITY_LOG_SISKA.md` entri 116.

---

## 10. Revisi 3 — Visual "Identik" dengan Widget Intercom Asli (atas permintaan user)

User memberi 4 screenshot referensi widget Intercom SUNGGUHAN (dipakai situs Anthropic sendiri: docs.anthropic.com) dan minta desain "identik". Revisi ini HANYA visual/UX detail per tab -- struktur tombol mengambang+panel (Revisi 2) dan seluruh backend (Section 5) TIDAK berubah.

**Perubahan per tab**:
- **Header 2-mode**: gelap (`.zammad-chat-header--dark`, dekat hitam) dengan sapaan besar 2 baris untuk tab Home; putih dengan judul polos DI TENGAH ("Messages"/"Help") untuk tab lain -- KECUALI tab Messages sedang ada agent yang menangani, tetap tampilkan info agent (nama+status, pola SAMA sejak Fase 5) apa pun tab yang aktif saat itu terjadi. Method baru `updateHeader(tabName)` jadi SATU titik keputusan (bukan tersebar di 3 tempat seperti sebelumnya).
- **Ikon tab bar**: outline (abu-abu, nonaktif) vs terisi/solid (biru, aktif) -- 2 SVG terpisah per tombol, ditoggle lewat CSS, BUKAN cuma ganti warna ikon yang sama.
- **Tab Help**: kotak pencarian bergaya pil dengan ikon kaca pembesar; baris hasil dengan judul+cuplikan (2 baris, line-clamp) + chevron di kanan.
- **Tab Messages**: status "No messages" (ikon+judul+subteks+tombol CTA "Send us a message" berikon kirim) ditampilkan SEBELUM form pra-chat -- BUKAN langsung lompat ke form seperti Revisi 2. Tombol "Send us a message" di Home tetap langsung ke form pra-chat (skip status kosong, niat sudah jelas dari Home).

**Yang SENGAJA TIDAK direplikasi** (keputusan sadar, bukan lupa):
| Elemen referensi | Alasan tidak diikuti |
|---|---|
| Daftar "16 collections" (navigasi kategori KB) di tab Help | Tetap search-only sesuai keputusan desain awal (Section 6) -- 30 artikel KB yang ada semuanya belum di-publish, navigasi kategori kosong tidak berguna sekarang, kerja baru kalau nanti dibutuhkan |
| Persona bot "Fin AI Agent" + tombol quick-reply ("Login now"/"I can't login") | SISKA menghubungkan ke AGENT MANUSIA sungguhan, bukan bot AI -- meniru elemen ini akan MENYESATKAN pelanggan sungguhan yang mengira sedang bicara dengan bot |

**3 bug ditemukan & diperbaiki sendiri selama implementasi**:
1. `onWebSocketClose` (KEDUA varian) masih menyentuh `@el` (panel) untuk class `is-loaded`/`is-shown` -- sisa Revisi 2 yang lupa dipindah ke `@launcherEl`, ditemukan lewat pembacaan ulang kode sebelum menyentuh area yang sama.
2. `.zammad-chat-modal` (isi tab Messages: status kosong/form/waiting) `position: absolute` TANPA leluhur ber-`position` di dalam tab-body-nya sendiri -- containing block-nya jadi PANEL UTUH, `bottom: 0` ikut menutupi tab bar di bawahnya, memblokir klik pindah tab kapan pun tab Messages aktif & modal terisi (baru selalu ke-trigger sejak status kosong SELALU ada isinya). Ditemukan lewat Playwright ("intercepts pointer events"), diperbaiki dengan `position: relative` di `.zammad-chat-tab-body`.
3. Ikon SVG tab bar baru tanpa `width`/`height` eksplisit -- render di ukuran default browser, membuat label "Messages" turun ke baris terpisah. Ditemukan lewat screenshot Playwright, diperbaiki dengan ukuran eksplisit di CSS.

**Catatan encoding** (bukan bug fitur): placeholder "Search for help…" sempat tampil mojibake di screenshot test PERTAMA -- dikonfirmasi byte UTF-8 benar di source & bundle, murni karena halaman test fixture Playwright tidak mendeklarasikan `<meta charset="utf-8">`. Dicatat: server SISKA sendiri mengirim `chat.js` tanpa `charset=utf-8` eksplisit di header `Content-Type` (kondisi lama, bukan baru dari revisi ini) -- risiko sama secara teori berlaku ke string "Compose your message…" yang sudah ada sejak sebelum proyek ini; TIDAK diperbaiki di sini (di luar scope, nyaris semua website modern sudah mendeklarasikan UTF-8 sendiri).

**Diverifikasi Playwright genuinely lintas-domain**: tampilan tiap tab dibandingkan visual ke referensi (sangat mendekati); regresi PENUH (KB search, kirim pesan, upload attachment lintas-domain) diulang & lolos tanpa error; tampilan mobile (390x800) dicek ulang.

Detail lengkap di `docs/ACTIVITY_LOG_SISKA.md` entri 117.

---

## 11. Revisi 4 — Reskin ke Design System Able Pro (starter kit user) + Eksekusi Kode

User punya starter kit dashboard sendiri (`able-pro-vue-v1.7.0`, Vue/Vuetify) dan minta widget mengikuti gaya visual template itu (bukan lagi meniru Intercom/Claude secara bebas) -- token warna/radius/font diambil LANGSUNG dari `src/plugins/vuetify.ts` & `src/scss/_variables.scss` template tsb, komponen chat-nya sendiri (`ChatDetail.vue`/`ChatListing.vue`/`ChatSendMsg.vue`) jadi referensi pola visual (bubble, header, search box, list hasil).

Proses: mockup di-iterasi dulu lewat Artifact (Design canvas) sampai disetujui user per bagian (header, logo, form pra-chat, layar menunggu, emoji picker, dst.), BARU dieksekusi ke kode sungguhan atas instruksi eksplisit "eksekusi widget chat dulu" (sisi customer/widget saja -- sisi agent/settings/riwayat/user-login masih mockup, menyusul).

**Token desain** (dicek ke kode Able Pro, bukan ditebak): primary `#4680FF`, borderLight `#e8ebee`, lightText/secondary `#5B6B79`, success `#2ca87f`, warning `#e58a00`, radius md `8px`/lg `12px`. Font "Inter" TANPA Google Fonts (widget di-embed lintas-domain, tidak sepadan menambah request eksternal untuk semua situs klien).

**Perubahan konten/struktur** (bukan cuma warna): header 2-mode (tint biru muda utk Home, bukan gelap; putih judul-tengah utk Messages/Help/info-agent), logo placeholder di Home, tab bar disederhanakan jadi 1 ikon/tombol (Able Pro tidak punya pola outline+filled), alur Messages disederhanakan (form pra-chat langsung, TANPA status "belum ada percakapan" -- fitur itu dari Revisi 3 DIHAPUS lagi sesuai urutan mockup baru), form pra-chat & layar menunggu direstyle total (spinner cincin, field berlabel), tab Help (ikon kiri, ikon-avatar hasil, cuplikan 1 baris bukan 2), bubble agent jadi putih+border (bukan abu-abu solid). **Fitur baru murni**: emoji picker (panel grid 18 emoji, sisip ke kursor kotak ketik) -- tidak ada di desain manapun sebelumnya, permintaan baru di iterasi mockup.

**2 bug ditemukan & diperbaiki lewat Playwright**: (1) badge posisi antrean kehilangan spasi ("position1.") -- `display: inline-flex` pada badge membuat whitespace text node di antara teks & `<strong>%s</strong>` hilang secara visual (kuirk flexbox), diganti `inline-block`; (2) emoji tampil kotak "tofu" di server pengujian -- dikonfirmasi via `fc-list` server ini memang tidak punya font emoji sama sekali (bukan bug widget), tetap ditambahkan font emoji eksplisit ke font-family sebagai praktik defensif.

**Diverifikasi Playwright genuinely lintas-domain**: alur penuh Home (logo+sapaan) → Help (cari KB) → Home → "Send us a message" langsung ke form pra-chat (dikonfirmasi TIDAK lewat status kosong) → submit → layar menunggu (dikonfirmasi tampil via `initialQueueDelay` 10 detik Fase 5, bukan diasumsikan) → agent accept → tersambung → emoji picker end-to-end (buka, pilih, tersisip, panel tertutup otomatis) → kirim pesan → upload attachment lintas-domain tetap berhasil (regresi CORS Fase 7 tidak rusak). Zero console error.

Detail lengkap di `docs/ACTIVITY_LOG_SISKA.md` entri 118.

---

*Dokumen ini sudah diimplementasikan penuh untuk sisi WIDGET CUSTOMER & diverifikasi (Revisi 4). Sisi agent/settings/riwayat/user-login masih tahap mockup Artifact. Belum di-commit ke git -- menunggu konfirmasi eksplisit user.*
