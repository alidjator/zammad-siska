# Desain Teknis — Live Chat Follow-Up Tiket untuk Semua User Login (Fase 6)

**Status:** **DIIMPLEMENTASIKAN & DIVERIFIKASI end-to-end lewat Playwright** (Section 7/7.1). `chat_self_service_enabled` masih `false` (default aman) -- BELUM diaktifkan untuk user sungguhan, menunggu keputusan user kapan mengaktifkan untuk rollout ke semua 72.040 user.
**Bergantung pada:** Fase 5 (`docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md`) — seluruh infrastruktur live chat (event WebSocket, model `Chat`/`Chat::Session`/`Chat::Message`, attachment, reply-to) dipakai ulang APA ADANYA. **Auto-create ticket (Item 5) TIDAK dipakai untuk fitur ini** — lihat Section 5.

---

## 1. Requirement dari User (revisi)

Permintaan awal: *"saya mau semua user punya fitur chat, untuk user yang login, gunakan jendela chat nya sama seperti jendela chat agent, hanya tidak ada fitur pengaturan attachment seperti agent, dan tidak bisa enable disable chat."*

Direvisi user setelah desain pertama: *"saya mau, untuk chat user ini hanya untuk follow up ticket, jadi chat akan muncul kalau sudah membuat ticket, dan chat tidak membuat ticket, tapi chat dikaitkan dengan ticket yang sudah ada."*

Digabung jadi requirement final:
1. Semua user login bisa pakai live chat, UI-nya `ChatWindow` yang SAMA PERSIS dengan agent (Section 1 desain pertama, TIDAK berubah).
2. **Chat HANYA untuk follow-up tiket yang SUDAH ADA** — bukan cara baru untuk membuat tiket. Titik masuknya: halaman "Live Chat" terpisah berisi DAFTAR tiket milik user sendiri, tiap baris ada tombol "Chat" (dipilih user lewat AskUserQuestion, bukan tombol di halaman detail tiket — supaya tidak menyentuh kode `ticket_zoom` yang kompleks & dipakai bersama agent).
3. **Chat TIDAK membuat tiket baru** — `Chat::Session` yang dibuat langsung DIKAITKAN ke `ticket_id` yang sudah ada (dipilih user dari daftar), bukan menunggu agent accept baru dibuatkan tiket seperti alur Item 5 untuk visitor anonim.
4. Cuma tiket **berstatus terbuka** (bukan closed/merged) yang muncul di daftar & bisa di-follow-up (dipilih user lewat AskUserQuestion).
5. **Routing DIREVISI jadi configurable** (permintaan lanjutan user: *"untuk routing, saya mau dibuat configurable di setting, bisa diarahkan ke group terkait, tapi default ke customer service"*) — bisa diarahkan ke topik chat milik Group pemilik tiket KALAU sudah dikonfigurasi admin, otomatis fallback ke topik "Customer Service" kalau belum/tidak match. Detail mekanisme di Section 5.6.
6. **TIDAK termasuk** (tidak berubah dari desain pertama): pengaturan enable/disable attachment ala agent, kemampuan enable/disable topik chat.
7. **Riwayat chat sebelumnya (Fase 5, Section 5.1.7) ditampilkan di KEDUA sisi** — user & agent — beda dari Fase 5 yang sengaja cuma agent (waktu itu "customer" masih visitor anonim). Detail di Section 5.5.

---

## 2. Temuan Riset (Tidak Berubah dari Revisi Pertama)

Lihat detail lengkap di riwayat — ringkasannya:
- Backend live chat (`chat_session_init`, `chat_status_customer`, `chat_session_message`) tidak mengecek permission "siapa boleh jadi customer" — status agent/customer sebuah pesan murni dari `created_by_id == chat_session.user_id`, ditentukan HANYA lewat `ChatSessionStart#run` yang tetap mewajibkan `chat.agent`. User login manapun otomatis berperan "customer", tidak mungkin tertukar "agent".
- Checkbox attachment & toggle enable/disable topik 100% hidup di `App.CustomerChat` (controller `#customer_chat`), BUKAN bagian `ChatWindow` — pakai ulang `ChatWindow` tanpa `App.CustomerChat` otomatis mengecualikan keduanya.
- Pengaman kapasitas (`max_queue`, status `offline`/`no_seats_available`/`online` dari `Chat#customer_state`) sudah native, dipakai ulang.

**Temuan BARU (khusus revisi ini)**: `Chat::Session.ticket_id` (kolom yang SUDAH ADA sejak Fase 5 Item 5) selama ini SELALU diisi BELAKANGAN oleh `create_ticket_for_chat_session` (dipanggil dari `ChatSessionStart#run`, saat agent accept). Untuk model follow-up, urutannya DIBALIK: `ticket_id` sudah diketahui SEJAK AWAL (user memilih dari daftar tiketnya sendiri SEBELUM chat dimulai), jadi tinggal diisi lebih awal (saat `chat_session_init`) dan proses auto-create di `ChatSessionStart#run` cukup DILEWATI kalau `ticket_id` sudah terisi — bukan logika baru, cuma guard tambahan di logika yang sudah ada.

`sync_message_to_ticket` (`chat_session_message.rb`, Fase 5 Section 5.1.4) **TIDAK PERLU DIUBAH SAMA SEKALI** — logikanya sudah generic: kalau `chat_session.ticket_id` ada, tiap pesan baru (dari kedua sisi) otomatis jadi `Ticket::Article` di tiket itu. Ini justru PAS dengan makna "follow-up" — percakapan live chat otomatis jadi bagian riwayat tiket yang sudah ada, terlepas dari KAPAN/BAGAIMANA `ticket_id` itu terisi.

---

## 3. Arsitektur (Revisi)

```
User login klik menu "Live Chat" (baru, permission ['*'])
        |
        v
App.MyChat controller
        |
        | cari tiket MILIK USER SENDIRI (customer_id = akun login)
        | dengan state_type BUKAN closed/merah (lihat Section 5.3)
        |
        v
render DAFTAR tiket (nomor, judul, status) + tombol "Chat" per baris
  -- TIDAK ADA tiket terbuka -> pesan "Belum ada tiket yang bisa di-chat"
  -- (bukan tombol "Mulai Chat" bebas seperti desain pertama)
        |
        v  (klik "Chat" pada salah satu baris tiket)
kirim chat_session_init DENGAN ticket_id tiket yang dipilih
  (chat_id topik: coba cari topik chat yang terkait Group tiket ini
   dulu, fallback ke Setting topik default kalau tidak ketemu/tidak
   ada agent aktif -- Section 5.6; name/email dari akun login --
   Section 5.1, TIDAK BERUBAH dari desain pertama)
        |
        v
SERVER VALIDASI (Section 5.2): tiket itu benar milik user ini? masih
terbuka? -- kalau tidak, ditolak (chat_session_init gagal, pesan jelas)
        |
        v
Chat::Session dibuat dengan ticket_id SUDAH TERISI sejak awal
        |
        v
terima chat_session_queue (posisi antrean) -> modal "menunggu agent..."
di atas kerangka .chat-window (TIDAK BERUBAH dari desain pertama)
        |
        v  (agent accept dari #customer_chat, TIDAK BERUBAH)
terima chat_session_start
        |
        | create_ticket_for_chat_session TETAP DIPANGGIL seperti biasa,
        | TAPI langsung return di baris pertama karena ticket_id sudah
        | ada -- TIDAK ADA tiket baru dibuat (Section 5.4)
        |
        v
modal dibuang, instantiate App.ChatWindow(session: data.session)
  -- KOMPONEN YANG SAMA PERSIS dipakai agent, TIDAK BERUBAH
        |
        v
percakapan berjalan; SETIAP pesan otomatis tersinkron sebagai
Ticket::Article ke tiket yang dipilih di awal (sync_message_to_ticket,
TIDAK BERUBAH -- sudah generic sejak Fase 5)
```

---

## 4. Perubahan Frontend (Revisi)

Section 4.1 (ekspor `ChatWindow` jadi `App.ChatWindow`) dan Section 4.3 (route+menu `#my_chat`, `permission: ['*']`) **TIDAK BERUBAH** dari desain pertama.

### 4.2 Controller `App.MyChat` (state `idle` berubah total, sisanya sama)

- **`idle`** (BERUBAH): bukan lagi tombol "Mulai Chat" tunggal. Ambil daftar tiket milik user via API pencarian tiket yang SUDAH ADA (`App.Ticket`/endpoint search, filter `customer_id: <id akun sendiri>` + status bukan closed/merged — query yang SAMA jenisnya dengan yang dipakai halaman "Overviews" yang customer sudah bisa akses, bukan endpoint baru). Render `my_chat/ticket_list.jst.eco`: tabel/daftar sederhana (nomor tiket, judul, status, tombol "Chat"). Kalau daftar kosong: pesan "Belum ada tiket yang bisa di-follow-up lewat chat".
- **`waiting`**: TIDAK BERUBAH dari desain pertama — kirim `chat_session_init` (sekarang MENYERTAKAN `ticket_id` dari baris yang diklik), modal menunggu + posisi antrean.
- **`active`**: TIDAK BERUBAH — `new App.ChatWindow(session: data.session, ...)`.
- Tambahan kecil: kalau `chat_session_init` ditolak server (tiket sudah tidak eligible lagi, misal keburu di-close agent lain di saat bersamaan — race condition wajar untuk ditangani, bukan diabaikan), tampilkan pesan error & kembali ke daftar tiket (refresh).

### 4.4 View baru (revisi nama)

- `app/assets/javascripts/app/views/my_chat/ticket_list.jst.eco` (GANTI `index.jst.eco` dari desain pertama) — daftar tiket + tombol Chat per baris.
- `app/assets/javascripts/app/views/my_chat/waiting.jst.eco` — TIDAK BERUBAH.
- `app/assets/stylesheets/my_chat.scss` — TIDAK BERUBAH konsepnya, cuma styling untuk daftar tiket alih-alih satu tombol.

---

## 5. Perubahan Backend (Revisi)

### 5.1 Identitas otomatis dari akun (TIDAK BERUBAH dari desain pertama)

`ChatSessionInit#run`, blok `if @session && @session['id']` tetap mengambil `name`/`email` dari `User.find(@session['id'])`, mengabaikan payload — lihat desain pertama Section 5.1 untuk detail & alasannya (keamanan + tiket tertaut ke akun asli).

### 5.2 `ticket_id` WAJIB & divalidasi untuk jalur user login

Payload `chat_session_init` mendapat field baru `ticket_id` (cuma dipakai jalur user login; jalur widget publik anonim TIDAK mengirim ini sama sekali, tetap TIDAK PUNYA tiket sampai `ChatSessionStart` seperti biasa — Section 5.4 menjaga 2 jalur ini tetap terpisah).

```ruby
if @session && @session['id']
  if !Setting.get('chat_self_service_enabled')
    return { event: 'chat_session_init', data: { state: 'failed', message: __('Live chat is not available right now.') } }
  end

  # WAJIB terkait tiket yang SUDAH ADA -- lihat DESIGN_CHAT_SELF_SERVICE.md
  # Section 1 poin 3: fitur ini cuma untuk follow-up, BUKAN cara baru
  # bikin tiket. Tiket harus MILIK user yang login (bukan tiket siapa
  # pun) dan masih TERBUKA (bukan closed/merged) -- dicek ULANG di
  # server, bukan cuma percaya UI (yang harusnya sudah memfilter, tapi
  # payload WebSocket bisa saja dipanggil langsung/dimanipulasi).
  ticket = Ticket.find_by(id: @payload['data']['ticket_id'])
  chat_user = User.find_by(id: @session['id'])

  if !ticket || ticket.customer_id != chat_user.id || ticket.state.state_type.name.in?(%w[closed merged])
    return {
      event: 'chat_session_init',
      data:  { state: 'failed', message: __('This ticket is not available for chat follow-up.') },
    }
  end

  name  = chat_user.fullname
  email = chat_user.email
else
  # jalur ANONIM (widget publik) -- TIDAK BERUBAH dari Fase 5.
  ...
end
```

`Chat::Session.create` mendapat tambahan `ticket_id: ticket&.id` (nil untuk jalur anonim, terisi untuk jalur follow-up), DAN `preferences[:self_service] = true` untuk jalur user login (dipakai lagi di Section 5.7 untuk membedakan dari jalur widget anonim di titik KEMUDIAN, saat `ChatSessionStart#run` sudah tidak tahu lagi dari mana `chat_session_init` awalnya berasal).

**Dicek dulu**: kategori state Zammad di instance ini via `Ticket::StateType` — 6 kategori (`new`, `open`, `pending reminder`, `pending action`, `closed`, `merged`), state kustom seperti "in progress"/"eskalasi" masuk kategori `open`, "pending close" masuk `pending action`. Jadi filter "terbuka" = `state_type.name` BUKAN `closed`/`merged` — otomatis mencakup semua state kustom yang mungkin ditambah nanti tanpa perlu update kode, bukan daftar nama state yang di-hardcode satu-satu.

### 5.3 Query daftar tiket (frontend, bukan endpoint baru)

Tidak perlu controller/endpoint Rails baru — `App.MyChat` query tiket lewat mekanisme pencarian tiket yang SUDAH dipakai customer (dasar yang sama dengan "Overviews" yang sudah bisa diakses `ticket.customer`), difilter `customer_id` = akun sendiri + `state.state_type.name` bukan closed/merged. Detail query final ditentukan saat implementasi (menyesuaikan API pencarian tiket yang tersedia di frontend, `App.Ticket.search` atau sejenisnya) — TIDAK butuh migration/endpoint baru.

### 5.4 `create_ticket_for_chat_session` DILEWATI kalau sudah terkait tiket

`ChatSessionStart#run` (`create_ticket_for_chat_session`), baris PALING ATAS ditambah guard:

```ruby
def create_ticket_for_chat_session(chat_session)
  return if chat_session.ticket_id.present?
  # ...logika auto-create yang SUDAH ADA, TIDAK BERUBAH,
  # tetap jalan seperti biasa untuk jalur WIDGET ANONIM (Item 5)...
end
```

Ini SATU-SATUNYA perubahan di file ini. Karena jalur follow-up SUDAH mengisi `ticket_id` sejak `chat_session_init` (Section 5.2), guard ini membuat auto-create dilewati TOTAL untuk jalur tsb — memenuhi requirement "chat tidak membuat tiket". Jalur widget anonim (Item 5 original) sama sekali tidak terpengaruh (`ticket_id` mereka memang masih kosong di titik ini, guard tidak pernah aktif untuk mereka).

### 5.5 Riwayat chat sebelumnya ditampilkan di KEDUA sisi (user & agent)

Atas permintaan user: berbeda dari Fase 5 Item 5.1.7 (yang SENGAJA cuma sisi agent, karena waktu itu "customer"-nya visitor anonim tanpa akun) — untuk Fase 6, karena "customer"-nya adalah USER YANG LOGIN dengan akun & email asli, tidak ada alasan lagi menyembunyikan riwayatnya dari dirinya sendiri. Jadi panel riwayat ("Previous chats from this visitor:", lengkap dengan transkrip & link tiket, sudah ada sejak Fase 5 entry 100-102) harus muncul di jendela `ChatWindow` KEDUA belah pihak untuk sesi follow-up.

**Ditemukan celah desain saat menelusuri ini**: payload `chat_session_start` yang dikirim ke sisi CUSTOMER (blok `if session_attributes['messages'].blank?` di `ChatSessionStart#run`) TERNYATA berbentuk BEDA dari yang dikirim ke agent — cuma field datar (`state`, `agent`, `session_id`, `chat_id`, `attachment_enabled`), BUKAN `{ session: session_attributes }` yang berisi SEMUA atribut sesi (termasuk `previous_sessions`). Ini karena widget publik anonim (Fase 5) punya parser JS SENDIRI yang memang cuma butuh field-field itu. Padahal `App.ChatWindow` (dipakai Fase 6 di KEDUA sisi) butuh bentuk `{ session: {...} }` yang lengkap, PERSIS seperti yang diterima agent -- gap ini HARUS diperbaiki supaya Fase 6 bisa jalan sama sekali (bukan cuma soal riwayat), riwayat cuma menyingkap gap ini lebih awal.

Diperbaiki dengan CABANG BARU di `ChatSessionStart#run`, dipilih berdasarkan `preferences[:self_service]` (ditandai saat `chat_session_init`, Section 5.2) -- BUKAN mengubah jalur widget anonim yang sudah ada:

```ruby
if session_attributes['messages'].blank?
  data = if chat_session.preferences[:self_service]
           # Fase 6 -- customer di sini adalah App.ChatWindow (sama
           # persis komponennya dengan agent), butuh bentuk payload
           # LENGKAP yang sama seperti agent terima, termasuk
           # previous_sessions -- BUKAN payload datar ala widget lama.
           {
             event: 'chat_session_start',
             data:  { session: session_attributes },
           }
         else
           # widget anonim (Item 5 asli) -- TIDAK BERUBAH SAMA SEKALI.
           user = chat_session.agent_user
           {
             event: 'chat_session_start',
             data:  {
               state:               'ok',
               agent:               user,
               session_id:          chat_session.session_id,
               chat_id:             chat_session.chat_id,
               attachment_enabled:  chat_session.attachment_enabled?,
             },
           }
         end
  chat_session.send_to_recipients(data, @client_id)
end
```

Karena `session_attributes['previous_sessions']` (dihitung lewat `Chat::Session#previous_sessions_summary`, Section 2) SUDAH otomatis ikut di dalam `session_attributes` yang dikirim ke KEDUA sisi lewat cabang `self_service` ini, riwayat + transkrip lengkap + affordance panah (Fase 5 entry 100-102) OTOMATIS muncul di jendela `ChatWindow` milik USER juga -- **tidak perlu perubahan apa pun lagi** di template (`chat_window.jst.eco`) atau CSS (`chat_enhancements.scss`), karena keduanya sudah generic (dipakai render `@previousSessions` siapa pun yang membuka jendela itu, bukan spesifik agent). Ini murni konsekuensi dari "pakai ulang `ChatWindow` yang sama persis" (requirement awal Fase 6) diterapkan sampai ke titik ini.

**Cakupan riwayat untuk sisi user**: dicocokkan by EMAIL, SAMA seperti sisi agent (Section 2, tidak ada logika baru) -- karena email user login SELALU stabil (bukan ketikan manual seperti visitor anonim), riwayat yang muncul akan konsisten across SEMUA tiket yang pernah mereka follow-up lewat chat, bukan cuma tiket yang sedang dibuka saat itu.

### 5.6 Routing configurable: topik chat milik Group tiket, fallback ke Customer Service

Revisi atas permintaan user: *"untuk routing, saya mau dibuat configurable di setting, bisa diarahkan ke group terkait, tapi default ke customer service"*.

**Ditemukan sumber kebenaran yang SUDAH ADA, tidak perlu struktur baru**: tiap topik `Chat` (`Admin > Channels > Chat`) SUDAH BISA punya `preferences[:ticket_group_id]` (Fase 5, Section 5.1.3 -- awalnya dipakai untuk arah SEBALIKNYA: "kalau chat DI TOPIK INI diterima & belum ada tiket, buat tiketnya di Group X"). Untuk Fase 6, field yang SAMA dipakai untuk arah SEBALIKNYA LAGI: cari topik `Chat` yang `preferences[:ticket_group_id]`-nya COCOK dengan Group pemilik tiket yang mau di-follow-up. Tidak perlu Setting mapping baru yang terpisah -- admin CUKUP membuat topik `Chat` baru (lewat Admin UI yang sudah ada) untuk departemen yang mau ditangani langsung, isi `ticket_group_id`-nya ke Group departemen itu, otomatis kepakai jalur ini.

```ruby
# Dipanggil dari ChatSessionInit#run, MENGGANTIKAN pemilihan chat_id
# yang sebelumnya cuma baca Setting chat_self_service_chat_id secara
# langsung -- sekarang itu jadi FALLBACK, bukan satu-satunya sumber.
def resolve_self_service_chat_id(ticket)
  default_chat_id = Setting.get('chat_self_service_chat_id')
  return default_chat_id if !Setting.get('chat_self_service_route_by_ticket_group')

  matching_chat = Chat.where(active: true).find do |chat|
    chat.preferences[:ticket_group_id].to_i == ticket.group_id
  end
  matching_chat&.id || default_chat_id
end
```

Setting baru `chat_self_service_route_by_ticket_group` (`frontend: true`, boolean, **default `true`**) -- saklar untuk MATIKAN TOTAL pencarian topik per-Group kalau admin mau, langsung pakai `chat_self_service_chat_id` apa pun kondisinya (skenario darurat/kesederhanaan, konsisten pola kill-switch di proyek ini).

**Kenapa hasilnya OTOMATIS "default ke Customer Service" hari ini**: instance ini SAAT INI cuma punya SATU topik `Chat` ("Customer Service", `preferences: {}` -- belum ada `ticket_group_id` sama sekali). Jadi `matching_chat` TIDAK PERNAH ketemu untuk Group mana pun sampai admin benar-benar membuat topik baru & mengisi `ticket_group_id`-nya -- perilaku hari ini otomatis SAMA seperti "selalu Customer Service" (opsi yang sebelumnya dipilih user), TAPI sudah siap "plug-and-play" begitu admin mau menambah topik per-departemen di kemudian hari, TANPA perlu perubahan kode/deploy ulang lagi -- pola yang sama seperti desain ClamAV di Fase 5 (Section 5.2.5).

**Catatan penting untuk admin (dicantumkan juga di dokumentasi Setting)**: sekadar mengisi `ticket_group_id` pada topik `Chat` baru TIDAK otomatis membuat agent departemen itu menerima chat -- topik itu tetap butuh MINIMAL SATU agent yang mengaktifkan topik tsb untuk dirinya sendiri (toggle "aktif" per-topik yang sudah ada sejak native Zammad), persis seperti "Customer Service" butuh 8 agent yang sudah mengaktifkannya. Kalau topik departemen ada tapi TIDAK ADA agent yang aktif di situ, `chat_status_customer`/`Chat#customer_state` akan mengembalikan `offline` untuk topik itu -- fallback ke Customer Service PERLU ditambahkan juga untuk skenario ini (bukan cuma "topik tidak match Group", tapi "topik match TAPI tidak ada agent aktif"), supaya user tidak macet kalau departemen tujuan belum siap:

```ruby
def resolve_self_service_chat_id(ticket)
  default_chat_id = Setting.get('chat_self_service_chat_id')
  return default_chat_id if !Setting.get('chat_self_service_route_by_ticket_group')

  matching_chat = Chat.where(active: true).find do |chat|
    chat.preferences[:ticket_group_id].to_i == ticket.group_id
  end
  return default_chat_id if !matching_chat

  # Topik-nya ADA & match Group, TAPI kalau tidak ada agent yang
  # aktif di situ sama sekali, tetap fallback -- jangan biarkan user
  # macet karena departemen tujuan belum ada yang standby.
  return default_chat_id if Chat.active_agent_count([matching_chat.id]).zero?

  matching_chat.id
end
```

### 5.7 Setting kill-switch & topik default — TIDAK BERUBAH

`chat_self_service_enabled` (default `false` sampai pengujian selesai) dan `chat_self_service_chat_id` (default topik "Customer Service", sekarang berperan sebagai FALLBACK -- Section 5.6) — sama persis desain pertama Section 5.2/5.3.

### 5.8 Tidak ada migration baru

`ticket_id` sudah ada di skema `chat_sessions` sejak Fase 5 — cuma diisi lebih awal untuk jalur ini. Tidak ada kolom/tabel baru.

---

## 6. Yang SENGAJA Tidak Diikutkan (TIDAK BERUBAH dari desain pertama)

Lihat tabel lengkap di riwayat desain pertama — checkbox attachment, toggle enable/disable topik, panel Waiting/Chatting/Active Agents, accept/transfer chat orang lain: semua TETAP tidak diikutkan, alasannya sama.

**Direvisi (khusus revisi ketiga)**: routing ke departemen pemilik tiket sekarang **configurable** (Section 5.6) — TIDAK lagi "sengaja tidak dirancang". Tapi karena instance ini SAAT INI cuma punya satu topik `Chat`, hasilnya hari ini tetap SELALU jatuh ke "Customer Service" (8 agent) sampai admin membuat topik baru per-departemen & mengisi `ticket_group_id`-nya — jadi TIDAK ADA perubahan perilaku LANGSUNG, cuma disiapkan supaya "plug-and-play" begitu dibutuhkan nanti (pola sama seperti desain ClamAV Fase 5). Percakapannya TETAP tersinkron otomatis ke tiket aslinya (Section 2) terlepas topik mana yang menangani live-nya.

---

## 7. Rencana Pengujian & Rollout

1. Setting `chat_self_service_enabled` dibuat dengan default **`false`** dulu.
2. Implementasi lengkap, dites dengan akun yang SUDAH ADA: `siska.tad.tester@pkp.co.id` (dibuatkan 1 tiket terbuka baru khusus untuk uji, "Test Fase 6 - Follow up chat") + `siska.chat.agent@pkp.co.id` (agent yang accept).
3. **[SELESAI, terverifikasi]** Verifikasi lewat browser sungguhan memakai Playwright (bukan lagi Puppeteer -- keputusan baru user berlaku mulai fitur ini): TAD tester buka menu "Live Chat" → lihat tiketnya sendiri di daftar → klik "Chat" → masuk antrean → agent accept dari `#customer_chat` (tidak berubah) → `App.ChatWindow` yang SAMA PERSIS muncul di kedua sisi → kirim pesan dua arah → **dikonfirmasi TIDAK ADA tiket baru terbuat** (`Ticket.where(customer_id: u.id)` tetap cuma 1 baris), pesan-pesan MUNCUL sebagai artikel baru di tiket yang dipilih di awal (3 artikel: catatan awal + 2 pesan chat, sender Customer/Agent benar).
4. **[SELESAI, terverifikasi]** Validasi keamanan (Section 5.2), lewat browser sungguhan (kirim `chat_session_init` mentah via `App.WebSocket.send`, bukan simulasi backend): `ticket_id` milik user LAIN → `{state: 'failed', message: 'This ticket is not available for chat follow-up.'}`. Tiket berstatus `closed` milik user SENDIRI → ditolak pesan yang SAMA. Tiket terbuka milik sendiri → TIDAK ditolak (lolos ke `chat_session_queue`).
5. Verifikasi kill-switch (widget publik tetap jalan normal saat `chat_self_service_enabled` dimatikan) -- belum dites eksplisit di sesi ini (kedua jalur SECARA KODE sudah dipastikan terpisah lewat percabangan `@session && @session['id']`, tapi belum ada uji browser langsung membuktikan widget publik tidak terganggu).
6. `chat_self_service_enabled` DIKEMBALIKAN ke `false` setelah pengujian selesai (bukan dibiarkan `true`) -- menunggu keputusan eksplisit user kapan diaktifkan untuk SEMUA 72.040 user, konsisten dengan rencana rollout bertahap.

### 7.1 Temuan & perbaikan SELAMA implementasi (bukan cuma desain di atas kertas)

Ditemukan lewat pengujian Playwright sungguhan, BUKAN dari membaca kode saja -- konsisten dengan pola yang sudah terbukti berulang kali sepanjang Fase 5 (bug baru ketahuan pas benar-benar diklik, bukan pas ditulis):

1. **`App.Chat.find(@session.chat_id)` mengembalikan `undefined` di sisi user, bukan agent** -- koleksi asset topik chat (`App.Chat`) cuma pernah dikirim server lewat broadcast `chat_status_agent` (KHUSUS agent), tidak pernah ke sisi customer/user. `ChatWindow`'s constructor (`chat.coffee`) yang MEMANGGIL `.displayName()` langsung tanpa cek null akan CRASH untuk jendela follow-up milik user. Diperbaiki dengan `@chat?.displayName() || ''` (safe-navigation) -- `@session.name` (SELALU terisi untuk sesi follow-up) tetap jadi sumber nama yang benar seperti sebelumnya.
2. **`chat.render()` tidak dipanggil otomatis oleh constructor `ChatWindow`** -- ditelusuri dari `App.CustomerChat#addChat` (jalur agent yang SUDAH ADA): `@workspace.append chat.el` diikuti `chat.render()` SECARA EKSPLISIT, bukan otomatis. Implementasi awal `App.MyChat#renderActive` cuma menempel `chat.el` ke DOM TANPA memanggil `render()` -- jendela terlihat ada (`<div class="chat-window">`) tapi ISINYA KOSONG (tidak ada kotak input dst.). Diperbaiki dengan meniru urutan PERSIS yang sama seperti `addChat`.
3. **Field query pencarian tiket salah** -- desain awal pakai `customer.id:X` (sintaks nested field), ternyata field yang benar (dikonfirmasi lewat `app/models/ticket/search.rb#search_query_extension`, kode native yang SUDAH ADA) adalah `customer_id:X` (flat). Diperbaiki di `App.MyChat#fetchTickets`.
4. **`App.TicketState`/`state_type` belum tentu tersedia di collection lokal tepat setelah login** -- filter "tiket terbuka" di frontend awalnya mengasumsikan `App.TicketState.find(ticket.state_id).state_type.name` SELALU ada, ternyata race kecil bisa membuatnya `undefined` (nyata terjadi di pengujian Playwright yang navigasi cepat sesudah login) -- CRASH (`Cannot read properties of undefined (reading 'name')`), bukan cuma salah tampil. Diperbaiki jadi DEFENSIVE: kalau info state belum tersedia, tiket TETAP ditampilkan (bukan disembunyikan/crash) -- filter di sini murni kenyamanan UX, backend (`ChatSessionInit#self_service_init`, sudah ada sejak desain awal) TETAP jadi penegak keamanan sesungguhnya yang menolak tiket closed/merged/bukan milik user apa pun yang ditampilkan.
5. **INFRASTRUKTUR (bukan bug kode): Elasticsearch memblokir semua penulisan index baru** -- ditemukan disk server 96% penuh (5,9GB tersisa dari 130GB) memicu "flood-stage watermark" ES, tiket BARU (termasuk tiket test) gagal ter-index sama sekali sehingga tidak muncul di pencarian manapun (bukan cuma fitur ini -- berpotensi memengaruhi Overview/pencarian tiket lain untuk data BARU secara umum). Dibersihkan Docker build cache (~6,9GB, aman/bukan data live) atas persetujuan user, disk turun ke 92% (di bawah threshold 95%), lalu index block DIBUKA MANUAL lewat Elasticsearch Index Settings API (`index.blocks.read_only_allow_delete: null`, wajib dilakukan eksplisit -- ES TIDAK otomatis membuka blokir sendiri walau disk sudah longgar lagi). **Catatan residual**: tiket-tiket lain yang mungkin gagal ter-index SELAMA periode disk penuh berlangsung (durasi tidak diketahui pasti) belum di-reindex ulang secara menyeluruh -- di luar cakupan Fase 6, disebutkan di sini supaya tidak terlupa.
6. **Kosmetik, tidak menghalangi fungsi**: `ChatWindow` memuat `App.WidgetTextModule` (fitur canned-response ala agent) tanpa syarat di `render()`, memicu 403 di console untuk user non-agent (tidak py permission `text_module`). Tidak menghalangi kirim/terima pesan (dikonfirmasi via pengujian) -- pola yang SAMA seperti widget TextModule di editor artikel tiket customer di tempat lain aplikasi ini (403/hasil kosong untuk role customer memang perilaku biasa, bukan regresi baru). Dibiarkan apa adanya, dicatat di sini kalau perlu dirapikan nanti.
7. **Ditemukan setelah user mencoba sendiri: tombol attachment tidak muncul di jendela follow-up milik user**, walau agent yang menangani sudah mengaktifkan attachment untuk dirinya (Fase 5, Section 5.2.6) dan Setting global juga nyala. Root cause: `ChatWindow#render()` (`chat.coffee`) menentukan tampil/tidaknya tombol attach dengan membaca `@Session.get('preferences')` -- yaitu preferensi SIAPA PUN yang SEDANG LOGIN melihat jendela itu. Untuk AGENT, ini benar (memang preferensi PER-AGENT, siapa pun agent yang login=siapa yang preferensinya relevan). Untuk USER LOGIN Fase 6 yang BUKAN agent, ini SALAH TOTAL -- preferensi attachment pribadi mereka tidak pernah ada artinya, hasilnya SELALU tersembunyi apa pun keputusan agent yang menangani.
    Diperbaiki dengan membedakan KEDUA kasus lewat perbandingan yang SAMA persis dipakai backend untuk menentukan agent vs customer (`created_by_id == chat_session.user_id`, lihat `chat_session_message.rb`): kalau user yang login SAAT INI adalah agent yang di-assign ke sesi ini (`@Session.get('id') is @session.user_id`), TETAP pakai preferensi pribadi seperti sebelumnya (perilaku agent TIDAK BERUBAH); kalau bukan (customer/self-service), pakai `@session.attachment_enabled` -- field BARU yang ditambahkan ke `session_attributes` (backend, `ChatSessionStart#run`) berisi hasil `chat_session.attachment_enabled?` yang SUDAH ADA sejak Fase 5, cuma belum pernah disertakan di payload lengkap ini sebelumnya (cuma ada di payload DATAR lama untuk widget anonim).
    Diverifikasi lewat Playwright: tombol attach SEKARANG muncul di jendela user (TAD tester) SAAT agent yang menangani sudah mengizinkan, DAN dikonfirmasi TIDAK ADA REGRESI di sisi agent (tombol attach agent tetap muncul seperti sebelumnya, memakai preferensi pribadi mereka sendiri seperti biasa).
8. **Ditemukan setelah user mencoba sendiri: jendela chat aktif TIDAK selebar/sepenuh sisi agent** -- terlihat nempel batas lebar 640px yang sengaja dipasang untuk 2 tampilan LAIN (daftar tiket, menunggu agent). Root cause: `.chat-window` (komponen `App.ChatWindow`) butuh PARENT ber-`display: flex` (`.chat-workspace`, class native yang sudah dipakai `App.CustomerChat`) supaya aturan sizing bawaannya sendiri (`.chat-window.is-open { flex: 1 0 25% }`) bisa membesar mengisi ruang tersedia -- `App.MyChat` sebelumnya menempel `chat.el` LANGSUNG ke elemen root yang dibatasi `max-width: 640px` tanpa flex context yang sesuai.
    Diperbaiki: `.my-chat-page` (root) diubah jadi flex column TANPA batas lebar (meniru `.chat` native, dipakai `App.CustomerChat`); batas lebar 640px dipindah ke class baru `.my-chat-content`, dipakai HANYA membungkus 2 tampilan lain (daftar tiket, menunggu) yang memang lebih enak dilihat sempit/rata tengah -- BUKAN jendela percakapan aktif. `App.MyChat#renderActive` membungkus `chat.el` dengan `<div class="chat-workspace">` (class NATIVE yang sudah ada, dipakai ulang apa adanya, BUKAN CSS baru) sebelum ditempel ke DOM, persis strukturnya sama seperti `App.CustomerChat#addChat`.
    Diverifikasi terukur lewat Playwright (`getBoundingClientRect()`, bukan cuma visual): lebar jendela chat = 1120px dari 1140px lebar halaman (~98%), konsisten di viewport lebar penuh -- sebelumnya (sebelum fix) akan tetap terpotong di ~640px berapa pun lebar viewport-nya.
9. **[Diverifikasi ulang, sempat tertunda]**: riwayat chat sebelumnya (poin 7 requirement, Section 5.5) DIKONFIRMASI benar-benar muncul di KEDUA sisi lewat pengujian 2-putaran (chat pertama → disconnect+close → chat KEDUA untuk tiket yang sama) via Playwright -- meta panel KEDUA sisi menampilkan "Previous chats from this visitor:" berisi sesi-sesi sebelumnya, lengkap dengan link "Open Ticket". Sempat butuh perbaikan SKRIP PENGUJIAN (bukan kode fitur) -- `ChatWindow#disconnect()` cuma memicu status "offline"/menampilkan tombol "Close", TIDAK otomatis memicu `removeCallback` yang mengembalikan `App.MyChat` ke daftar tiket -- perlu klik `.js-close` juga secara eksplisit sebelum bisa memulai sesi follow-up KEDUA (detail alur nyata, bukan bug, cuma perlu diketahui saat pengujian/dipakai).
10. **Atas permintaan user: tampilan "menunggu agent" diubah gaya loading native (full screen), teks TIDAK berubah** -- "jendela live chat ini dibikin gaya loading tabel, full screen, text tetap sama". Kartu kecil rata-tengah custom (`my-chat-waiting`, spinner CSS buatan sendiri) DIGANTI TOTAL dengan class NATIVE yang sudah dipakai tempat lain aplikasi ini untuk loading full-screen (dicek dulu markup aslinya di `layout_ref/loading_placeholder.jst.eco` sebelum ditiru): `.fullscreenMessage.fullscreenMessage--placeholder` (flex:1, mengisi ruang tersedia) + `.loading.icon` (spinner native, `zammad.scss`, animasi `rotateplane` yang sudah ada). Semua CSS custom lama (`my-chat-waiting*`, keyframe `my-chat-waiting-spin`) DIHAPUS -- cuma tersisa satu style kecil untuk teks posisi antrean. Teks "Waiting for an available agent..."/"Queue position: N" TIDAK berubah sama sekali, cuma pembungkusnya. Diverifikasi lewat Playwright: elemen `.fullscreenMessage` terukur 1112x800px (mengisi hampir seluruh area konten), teks tetap sama persis.

---

*Dokumen ini REVISI KETIGA. Implementasi SELESAI & terverifikasi end-to-end lewat Playwright (Section 7) -- lihat `docs/ACTIVITY_LOG_SISKA.md` entry terkait untuk kronologi lengkap. `chat_self_service_enabled` masih `false` (belum diaktifkan untuk user sungguhan), menunggu keputusan user.*
