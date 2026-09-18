# Fase 5 — Live Chat Enhancement (Item No. 5 & 6): Riset Teknis

Bagian dari Fase 5 (`docs/TASKLIST_SISKA.md`). Sesuai catatan `docs/Gap_Analysis_SISKA_Sintesis.md`: *"No. 5 & 6 paling berisiko — keduanya menyentuh channel Live Chat yang tidak punya extension point resmi."* Dokumen ini merangkum riset kode SEBELUM implementasi apa pun ditulis, mengikuti pola kerja proyek ini di fase-fase sebelumnya (riset dulu, sampaikan temuan, baru bangun kalau sudah disetujui).

## 1. Peta Arsitektur Live Chat

Ditelusuri dulu untuk memahami komponen yang terlibat, karena live chat ternyata TERSEBAR di 3 lapisan berbeda, bukan satu controller/model saja:

| Lapisan | Lokasi | Peran |
|---|---|---|
| Backend model & WebSocket event handler | `app/models/chat.rb`, `app/models/chat/session.rb`, `app/models/chat/message.rb`, `lib/sessions/event/chat_*.rb` | Menyimpan sesi/pesan, memproses event real-time (`chat_session_start`, `chat_session_message`, dst) |
| Frontend AGENT (aplikasi Zammad utama) | `app/assets/javascripts/app/controllers/chat.coffee` (956 baris) | Panel percakapan yang dilihat agent, termasuk tombol "Create Ticket" |
| Frontend CUSTOMER (widget terpisah) | `public/assets/chat/` (`chat.coffee`, `chat-no-jquery.coffee`, `gulpfile.js`, `package.json` SENDIRI) | Widget yang di-embed customer di website mereka lewat `<script>` tag, dibangun dengan toolchain build TERPISAH dari aplikasi Rails utama (bukan Vite/asset pipeline yang sudah kita pakai sepanjang sesi ini) |

`app/assets/javascripts/app/controllers/_channel/chat.coffee` (Admin > Channels > Chat) BUKAN bagian dari alur percakapan sungguhan -- itu halaman desainer widget (preview warna/ukuran/parameter embed), sempat salah diduga sebagai titik relevan di awal riset sebelum dibaca isinya.

## 2. Item No. 5 — Auto-Create Ticket Saat Sesi Chat Mulai

### 2.1 Titik Hook yang Ditemukan

Alur saat ini: agent klik "Accept" pada chat yang masuk (`chat.coffee#acceptChat`) mengirim WebSocket event `chat_session_start` ke server. Backend-nya (`lib/sessions/event/chat_session_start.rb#run`) melakukan:

1. Cari `Chat::Session` dengan `state: 'waiting'` paling lama.
2. Ubah `state` jadi `'running'`, isi `user_id` (agent yang menerima).
3. Kirim update ke customer & agent lewat WebSocket.

**Ini titik yang PALING PAS untuk hook "sesi chat mulai"** secara bisnis (bukan literal pesan pertama customer, tapi saat kontak manusia-ke-manusia benar-benar dimulai) -- di sinilah, kalau nanti dibangun, panggilan `Ticket.create!` otomatis akan ditaruh.

### 2.2 Temuan Penting: "Turn into Ticket" Saat Ini BUKAN Relasi Sungguhan

Dicek skema `chat_sessions` (`db/migrate/20120101000010_create_ticket.rb`) -- TIDAK ADA kolom `ticket_id` sama sekali. Dicek juga `chat.coffee#ticketCreate` (dipanggil tombol "Create Ticket" yang muncul SETELAH chat offline, `goOffline` method) -- yang terjadi HANYA:

```coffee
ticketCreate: (e) =>
  ...
  @navigate "#ticket/create/id/#{id}"
  ...
  clean_params =
    id: id
    prefilledParams:
      body: "#{http_type}://#{fqdn}/#{url}"  # link ke transkrip chat
      title: __('Chat')
  App.TaskManager.execute(controller: 'TicketCreate', params: clean_params, show: true)
```

Ini cuma MEMBUKA layar "New Ticket" dengan body pra-isi (link ke transkrip), bukan benar-benar membuat tiket secara otomatis -- agent MASIH harus mengisi Customer, Group, dan klik Submit secara manual. Tidak ada link balik (`ticket_id`) tersimpan di `Chat::Session` sama sekali setelah tiket dibuat.

### 2.3 Masalah Inti yang Belum Terpecahkan: Identitas Customer

Dicek `Chat::Session`/`Chat::Message`/`Chat` model dan widget (`public/assets/chat/chat.coffee`) -- **tidak ada mekanisme menangkap email/identitas customer sama sekali** sebelum/selama chat berlangsung secara default. Kolom `chat_sessions.name` cuma string bebas (nama tampilan opsional), BUKAN referensi ke `User`. Live chat visitor pada dasarnya ANONIM.

Ini masalah nyata untuk auto-create: model `Ticket` Zammad WAJIB punya `customer_id` (referensi ke `User` sungguhan). Kalau tiket dibuat OTOMATIS di titik `chat_session_start` (sebelum agent sempat menanyakan/mendapat email customer), sistem harus memutuskan sendiri siapa customer-nya -- pilihannya:

- **(a) Buat User placeholder/tanpa email** setiap sesi chat dimulai -- berisiko mencemari data customer (banyak akun "hantu" tanpa email asli), dan bertentangan dengan cara kerja fitur CSAT/notifikasi email yang sudah dibangun Fase 1 (mengandalkan pencocokan email untuk follow-up).
- **(b) Tunda pembuatan Customer sampai email diketahui**, tapi tiket TETAP dibuat sejak awal dengan Customer kosong/sementara, lalu di-update begitu diketahui -- lebih rumit, tapi tidak mencemari data.
- **(c) Cuma buat tiket kalau widget dikonfigurasi mewajibkan nama+email SEBELUM chat terhubung** (pre-chat form) -- TAPI dicek dulu, widget standar (`public/assets/chat/chat.coffee`) **tidak** punya form pra-chat bawaan yang mewajibkan ini; kalaupun ditambahkan, itu perubahan terpisah di widget yang juga perlu di-embed ulang oleh customer/website yang memakainya.

**Keputusan soal (a)/(b)/(c) ini murni keputusan desain milik user/bisnis, bukan sesuatu yang bisa saya tebak sendiri** -- karena implikasinya menyangkut kualitas data customer & alur kerja agent, bukan cuma soal teknis.

### 2.4 Ringkasan Risiko Item 5

- Titik hook backend JELAS dan terisolasi (`ChatSessionStart#run`), risiko regresi ke alur chat lain relatif kecil.
- TIDAK ada extension point resmi (event/hook Zammad yang didukung dokumentasi) -- perubahan ini menyisipkan logika baru langsung di file inti `lib/sessions/event/chat_session_start.rb`, berisiko konflik/hilang saat upgrade Zammad ke versi berikutnya (sama seperti peringatan Gap Analysis).
- Masalah identitas customer (2.3) BELUM terpecahkan -- perlu keputusan user sebelum desain teknis rinci bisa dilanjutkan.

## 3. Item No. 6 — Attachment di Live Chat

### 3.1 Temuan: Tidak Ada Mekanisme Attachment Sama Sekali

Dicek skema `chat_messages` (`db/migrate/20120101000010_create_ticket.rb`):

```ruby
create_table :chat_messages do |t|
  t.references :chat_session, null: false
  t.text    :content, limit: 20.megabytes + 1, null: false
  t.integer :created_by_id, null: true
  t.timestamps limit: 3, null: false
end
```

Cuma kolom `content` (teks/HTML), tidak ada kolom/relasi ke penyimpanan file apa pun. Ini mengonfirmasi temuan `Gap_Analysis_SISKA_Sintesis.md`: fitur ini genuinely tidak pernah dibangun Zammad di versi manapun, bukan cuma tidak terekspos di UI.

### 3.2 Yang Sudah Tersedia untuk Dipakai Ulang

Zammad punya model **`Store`** (`app/models/store.rb`) -- penyimpanan attachment generik POLIMORFIK, sudah dipakai `Ticket::Article`, Knowledge Base, dll (`Store.list(object: 'Ticket::Article', o_id: ...)`). Kalau fitur ini dibangun, `Chat::Message` bisa memakai mekanisme yang SAMA (`object: 'Chat::Message'`) alih-alih membuat sistem penyimpanan file baru dari nol -- ini mengurangi sebagian risiko yang disebut Gap Analysis ("praktis membangun ulang bagian dari core chat").

### 3.3 Cakupan Pekerjaan Kalau Tetap Dikerjakan

Attachment butuh perubahan di SEMUA lapisan sekaligus (lihat Section 1), bukan cuma satu file:

1. **Skema baru**: kolom/relasi di `chat_messages` ke `Store` (migration baru, menyentuh tabel inti chat).
2. **Endpoint upload baru**: WebSocket tidak cocok untuk transfer file besar -- perlu endpoint HTTP terpisah (mirip `POST /api/v1/attachment` yang sudah ada untuk ticket, tapi versi publik/tanpa-login untuk customer chat, dengan otorisasi berbasis `session_id` chat, BUKAN token user biasa).
3. **Widget customer** (`public/assets/chat/chat.coffee`, TOOLCHAIN BUILD SENDIRI, terpisah dari asset pipeline Rails yang sudah kita pakai sepanjang sesi ini) -- perlu UI upload/drag-drop baru, dan logika kirim file ke endpoint baru di poin 2.
4. **Panel agent** (`app/assets/javascripts/app/controllers/chat.coffee` + view `customer_chat/chat_message.jst.eco`) -- perlu render preview/link attachment di bubble pesan.
5. **Keamanan**: validasi tipe/ukuran file, mengingat ini upload dari PENGUNJUNG ANONIM (belum tentu customer terautentikasi) langsung ke sistem -- permukaan risiko baru yang tidak ada sebelumnya di alur chat (saat ini chat cuma menerima teks, tidak ada file apa pun yang masuk dari pengunjung anonim).

### 3.4 Catatan Baik: Widget Auto-Update, Bukan Perlu Re-Embed Manual

Satu kekhawatiran yang SEMPAT muncul saat riset lalu terbantahkan: widget customer (`chat.min.js`) disajikan LANGSUNG dari server Zammad kita sendiri (`public/assets/chat/chat.min.js`), customer cuma menaruh `<script src="https://server-kita/.../chat.min.js">` di website mereka -- BUKAN menyalin/vendor file itu ke server mereka sendiri. Jadi kalau widget ini diperbarui, SEMUA embed yang sudah terpasang otomatis dapat versi baru begitu halaman customer di-reload, TANPA perlu mereka pasang ulang manual. Ini mengurangi satu concern deployment, tapi tidak mengurangi cakupan pekerjaan teknisnya sendiri (Section 3.3).

### 3.5 Ringkasan Risiko Item 6

- Cakupan LEBIH LUAS dari Item 5 -- menyentuh 2 codebase/toolchain berbeda (Rails app + widget standalone), bukan 1 file terisolasi.
- Permukaan keamanan baru (upload file dari pengunjung anonim yang belum tentu customer terverifikasi).
- Tidak ada extension point resmi, sama seperti Item 5 -- risiko konflik upgrade Zammad di masa depan.
- Gap Analysis sendiri sudah menyarankan **workaround** (minta customer kirim lewat email/link cloud storage) sebagai alternatif yang jauh lebih murah & rendah risiko dibanding custom dev penuh.

## 4. Rekomendasi

Mengingat kedua item ini SUDAH ditandai sebagai risiko tertinggi di seluruh proyek (Gap Analysis: *"Custom dev di sini berpotensi jadi fork yang makin menyimpang dari upstream Zammad"*), dan riset ini menemukan Item 5 punya SATU keputusan desain terbuka (identitas customer, Section 2.3) yang harus dijawab user dulu sebelum desain teknis rinci bisa dilanjutkan, serta Item 6 ternyata genuinely lebih luas cakupannya (2 toolchain, permukaan keamanan baru) -- rekomendasi saya:

1. **Item 5** lebih layak dilanjutkan ke desain teknis rinci LEBIH DULU (titik hook jelas, 1 file inti, risiko lebih terkontrol) -- TAPI perlu keputusan Anda dulu soal identitas customer (opsi a/b/c, Section 2.3) sebelum saya menulis desain teknisnya.
2. **Item 6** saya sarankan dipertimbangkan ulang cost/benefit-nya dulu (sesuai catatan tasklist sendiri) -- workaround (link eksternal/email) jauh lebih murah, dan cakupan teknisnya (Section 3.3) genuinely besar untuk fitur yang belum pernah direalisasikan Zammad sendiri di versi manapun.

## 5. Desain Teknis Rinci

Ditulis setelah 2 keputusan Section 4 dijawab user: **Item 5** pakai opsi "wajibkan form nama+email sebelum chat mulai"; **Item 6** tetap lanjut ke desain teknis rinci meski risiko tinggi.

### 5.1 Item No. 5 — Auto-Create Ticket

#### Skema

Migration baru pada `chat_sessions` (tabel inti, perubahan berisiko sedang -- ditelusuri dulu tidak ada consumer lain yang butuh menyesuaikan skema secara ketat, cuma menambah kolom nullable):

```ruby
add_column :chat_sessions, :email,     :string, limit: 250, null: true
add_column :chat_sessions, :ticket_id, :integer,             null: true
add_index  :chat_sessions, [:ticket_id]
add_foreign_key :chat_sessions, :tickets
```

`email` diisi dari form pra-chat (di bawah). `ticket_id` diisi setelah tiket berhasil dibuat (5.1.3) -- dipilih kolom asli + index, BUKAN dititipkan ke `preferences` (seperti `participants`/`url`/`geo_ip` yang sudah ada di sana) karena relasi ini akan sering di-query untuk pelaporan (mis. "berapa sesi chat yang jadi tiket") -- kolom asli lebih murah untuk itu dibanding parse `preferences` tiap baris.

#### 5.1.1 Form Pra-Chat di Widget

`public/assets/chat/chat.coffee` (widget customer, toolchain build terpisah, lihat Section 1): sebelum tombol "Start Chat" mengirim `chat_session_init`, tampilkan step baru -- form 2 field (Nama, Email) dengan validasi format email di sisi client. `chat_session_init` HANYA dikirim setelah form ini valid & disubmit, sekarang membawa `name`/`email` di `data`.

#### 5.1.2 Backend: Validasi & Penyimpanan di `ChatSessionInit`

`lib/sessions/event/chat_session_init.rb#run` diubah: terima `name`/`email` dari `@payload['data']`, validasi ULANG di server (pertahanan berlapis -- validasi client BISA dilewati kalau seseorang memanggil WebSocket langsung tanpa lewat widget resminya). Kalau email kosong/tidak valid, `Chat::Session` TIDAK dibuat, balas event error yang membuat widget menampilkan lagi form dengan pesan kesalahan -- bukan diam-diam lolos ke status `waiting` tanpa identitas (yang akan menjegal 5.1.3 nanti).

#### 5.1.3 Backend: Pembuatan Tiket di `ChatSessionStart`

Titik hook (Section 2.1) tetap `lib/sessions/event/chat_session_start.rb#run`, dieksekusi PERSIS setelah `chat_session.state = 'running'` disimpan:

1. **Resolusi customer** -- pakai ULANG `Channel::Filter::BaseIdentifyUser.user_create(email:, firstname:, lastname: '')` (mekanisme find-or-create-by-email yang SUDAH dipakai & teruji jalur channel email Zammad sendiri, `app/models/channel/filter/base_identify_user.rb`) -- BUKAN menulis logika baru. Ini sekaligus menyelesaikan risiko "akun hantu tanpa email" yang jadi concern di Section 2.3: kalau visitor chat yang SAMA (email sama) datang lagi lain waktu, dia dikenali sebagai customer yang SAMA, bukan akun baru tiap kali.
2. **Resolusi Group** -- `chat.preferences[:ticket_group_id]` (override per-topik chat, opsional) kalau ada, kalau tidak fallback ke Setting baru `chat_auto_ticket_group_id` (global default). **Kalau KEDUANYA kosong** (belum dikonfigurasi admin sama sekali): auto-create DILEWATI dengan aman untuk sesi itu (chat manusia tetap jalan normal seperti sebelum fitur ini ada, tombol "Turn into ticket" manual yang lama tetap muncul sebagai fallback) -- bukan error/crash yang menghentikan chat. Ini pagar supaya fitur baru tidak diam-diam merusak chat yang sudah berjalan kalau konfigurasinya belum lengkap.
3. **Buat Ticket** -- `customer_id` dari poin 1, `group_id` dari poin 2, `title: "Live Chat - #{chat_session.name.presence || chat_session.email}"`, state awal sama seperti default tiket baru pada umumnya di deployment ini. Artikel pertama: catatan singkat "Live chat dimulai" (bukan transkrip penuh -- pada titik ini biasanya belum ada pesan sebelum agent bergabung, dikonfirmasi dari kode `chat_session_start.rb` yang sendiri mengumpulkan histori `Chat::Message` kosong di kasus umum).
4. **Simpan link balik** -- `chat_session.update!(ticket_id: ticket.id)`.

#### 5.1.4 Sinkron Transkrip Real-Time ke Tiket

`lib/sessions/event/chat_session_message.rb` (perlu dibaca detail strukturnya saat implementasi, belum dibaca detail di riset ini) ditambah: setelah `Chat::Message` baru tersimpan, KALAU `chat_session.ticket_id` terisi, buat juga 1 `Ticket::Article` di tiket itu yang mencerminkan pesan tsb (sender Customer/Agent sesuai pengirim pesan). Dengan ini tiket TETAP hidup mengikuti percakapan, bukan cuma cangkang kosong sampai chat selesai -- supervisor yang buka tiket di tengah chat langsung lihat percakapan sejauh itu.

#### 5.1.5 Tombol "Turn into Ticket" Existing -- Dihindari Duplikasi

`app/assets/javascripts/app/controllers/chat.coffee#ticketCreate` (dipanggil tombol yang muncul di `goOffline`) diubah: KALAU `session.ticket_id` sudah terisi (tiket sudah otomatis dibuat sejak awal), tombol berubah jadi "Open Ticket" -- `@navigate "#ticket/zoom/#{session.ticket_id}"` langsung, BUKAN membuka form New Ticket kosong lagi. Kalau `ticket_id` kosong (kasus fallback 5.1.3 poin 2, Group belum dikonfigurasi), tombol tetap berperilaku SAMA seperti sekarang (manual, prefill). Ini yang dimaksud tasklist "hindari duplikasi dengan tombol Turn into ticket existing".

#### 5.1.6 Keputusan Final

- **Group default `chat_auto_ticket_group_id`**: **"QA - Internal Testing"** (Group testing yang sudah ada sejak Fase 3, tanpa anggota, tidak mengirim notifikasi ke staf asli -- lihat `docs/TASKLIST_SISKA.md` "Di Luar Fase — Investigasi Notifikasi Email Selama Pengujian") -- dipakai untuk membangun & menguji fitur ini dulu. **Sebelum fitur ini diaktifkan untuk chat produksi sungguhan, Setting ini WAJIB diarahkan ulang ke Group produksi yang benar** -- kalau dibiarkan mengarah ke QA, semua tiket dari chat customer ASLI akan masuk ke Group tanpa anggota (tidak ada yang melihatnya).
- State/priority tiket baru: ikut default sistem (state pertama yang ditandai `default_create`, priority default) -- tidak perlu nilai khusus untuk tiket asal live-chat.

#### 5.1.7 Riwayat Chat Sebelumnya dari Customer yang Sama

Atas permintaan user -- fitur TAMBAHAN yang baru mungkin dibangun berkat 5.1.2/5.1.3: karena visitor sekarang WAJIB mengisi email sebelum chat mulai, dan `chat_session.email` tersimpan di setiap sesi, agent yang menerima chat BARU dari visitor yang PERNAH chat sebelumnya (email sama) bisa diberi tahu riwayatnya -- bukan cuma melihat percakapan yang sedang berjalan seolah-olah orang itu baru pertama kali kontak.

**Titik hook**: tetap `lib/sessions/event/chat_session_start.rb#run`, PERSIS sesudah 5.1.3 (resolusi customer & pembuatan tiket) -- di titik ini `chat_session.email` sudah pasti terisi (wajib sejak 5.1.2).

**Query riwayat**:
```ruby
previous_sessions = Chat::Session
  .where(email: chat_session.email)
  .where.not(id: chat_session.id)
  .where.not(email: [nil, ''])
  .order(created_at: :desc)
  .limit(5)
```
Dibatasi 5 sesi terakhir (bukan riwayat penuh tak terbatas) -- cukup untuk memberi konteks ke agent tanpa daftar panjang yang mengganggu, dan menghindari query berat untuk visitor yang sangat sering chat. Sesi-sesi LAMA (sebelum fitur 5.1.1-5.1.2 dibangun) TIDAK akan muncul di sini karena kolom `email`-nya kosong -- ini keterbatasan yang disengaja diterima (riwayat baru mulai tercatat sejak fitur ini aktif), bukan di-backfill dari data lama yang memang tidak pernah menyimpan email.

**Payload ke agent**: ditambahkan ke event `chat_session_start` yang SUDAH dikirim ke agent (Section 2.1/5.1.3, bagian `data.session`) -- field baru `previous_sessions`, masing-masing berisi `created_at` dan `ticket_id` (kalau sesi itu sempat jadi tiket, lihat 5.1.3) supaya agent bisa langsung klik ke tiket lama tsb.

**UI agent**: `app/assets/javascripts/app/controllers/chat.coffee` -- panel meta yang SUDAH ADA (`.js-meta`, dibuka lewat tombol info `.js-info`/`toggleMeta`, dipakai sekarang untuk form nama/tag sesi) diberi seksi baru "Riwayat Chat Sebelumnya": daftar tanggal + link ke tiket (kalau ada). Dipilih menumpang panel yang SUDAH ADA (bukan bikin UI baru terpisah) supaya tidak menambah elemen visual baru di jendela chat yang sudah padat.

**Privasi/lingkup**: cuma dicocokkan by EMAIL (bukan nama, yang bisa berbeda ejaan/tidak unik) -- konsisten dengan cara resolusi customer di 5.1.3 sendiri. Ditampilkan ke SEMUA agent yang menerima chat visitor itu (bukan cuma agent yang sama dengan sesi sebelumnya) -- selaras dengan cara kerja tiket biasa di Zammad (riwayat customer memang bisa dilihat semua agent berwenang, bukan rahasia per-agent).

### 5.2 Item No. 6 — Attachment di Live Chat

#### Skema

**TIDAK butuh migration baru sama sekali** -- ditelusuri lebih dalam dari riset awal (Section 3.2): `Store` (`app/models/store.rb`) sudah generik/polimorfik lewat pasangan `object` (nama class string) + `o_id` (id baris pemilik), TANPA kolom FK apa pun di tabel pemiliknya (dikonfirmasi dari `CanCloneAttachments` concern yang dipakai `Ticket::Article`, `Knowledge::Base::Answer`, dll -- semuanya cuma panggil `Store.create!(object:, o_id:, data:, filename:, preferences:)`, tidak ada migration attachment khusus di tabel mereka). `Chat::Message` bisa dipakaikan pola SAMA PERSIS: `Store.create!(object: 'Chat::Message', o_id: message.id, ...)`.

#### 5.2.1 Endpoint Upload Baru (Anonim, Discope Session)

Ditelusuri dulu (Section 3.3) apakah endpoint upload GENERIK yang sudah ada (`UploadCachesController`) bisa dipakai ulang -- TIDAK BISA, karena `prepend_before_action :authenticate_and_authorize!` mewajibkan sesi login Zammad, sedangkan visitor chat sama sekali tidak login. Dikonfirmasi juga lewat baca `ChatSessionInit#run` (tidak ada `permission_check` sama sekali, beda dari `ChatSessionUpdate`/`ChatSessionStart` yang mewajibkan `permission_check('chat.agent', 'chat')`) -- ini MEMANG desain resmi Zammad sendiri: jalur customer chat anonim BUKAN celah, tapi model otorisasi yang berbeda dari REST API biasa (dicek `session_id` yang valid, bukan token/login).

Endpoint baru (nama controller final ditentukan saat implementasi, mis. `Chat::AttachmentsController#create`) mengikuti pola otorisasi yang SAMA -- BUKAN `authenticate_and_authorize!`, tapi validasi manual: `session_id` di request harus cocok `Chat::Session` yang berstatus `waiting`/`running` (belum `closed`). Preseden yang sama sudah dipakai proyek ini sendiri di Fase 1 untuk halaman feedback CSAT publik (endpoint publik yang divalidasi lewat token per-tiket, bukan login) -- pola "otorisasi berbasis kepemilikan sesi, bukan akun" bukan hal baru di proyek ini.

#### 5.2.2 Alur Upload

1. Widget kirim file via `multipart/form-data` ke endpoint baru (WebSocket TIDAK dipakai untuk transfer file besar -- cuma dipakai untuk NOTIFIKASI setelah upload sukses, lihat poin 3).
2. Backend validasi: ukuran file (Setting `chat_attachment_max_size_mb`, lihat 5.2.2a), tipe/ekstensi file (Setting `chat_attachment_allowed_extensions`, lihat 5.2.4a).
3. Kalau lolos: buat `Chat::Message` baru (placeholder, mis. `content: '[attachment]'`), lalu `Store.create!(object: 'Chat::Message', o_id: message.id, data:, filename:, preferences: {content_type:})`.
4. Broadcast event WebSocket BARU `chat_session_attachment` (mengikuti pola `chat_session_message` yang sudah ada) ke lawan bicara (agent<->customer), berisi `message_id`/`filename`/`size`/`content_type`/URL download.
5. **Kalau `chat_session.ticket_id` terisi** (integrasi dengan Item 5, 5.1.3): pakai ULANG pola `Store.create!` yang sama (persis seperti `clone_attachments` di `CanCloneAttachments`, Section 3.2) untuk menyalin attachment yang sama ke `Ticket::Article` yang baru dibuat di poin 5.1.4 -- supaya file yang dikirim customer juga langsung terlihat di tiket, bukan cuma di jendela chat.

#### 5.2.2a Setting untuk Ukuran Maksimum Upload

Atas permintaan user, batas ukuran file (5.2.4, sebelumnya diusulkan sebagai angka tetap 5 MB) dibuat jadi Setting -- pola yang sama dengan `report_preview_per_page`/`aux_status_manage_per_page` sepanjang proyek ini (Setting sebagai sumber kebenaran, bukan angka hardcode).

**Setting baru**: `chat_attachment_max_size_mb` (`frontend: false`, cuma dibaca backend saat validasi upload) -- angka (MB), default **5**. Dicek dulu apakah ada Setting ukuran-file GENERIK yang bisa dipakai ulang di app ini -- ditemukan `es_attachment_max_size_in_mb` yang sudah ada, TAPI itu untuk batas indexing Elasticsearch (tujuan beda: mencegah file besar memperlambat pengindeksan pencarian, bukan mengontrol apa yang BOLEH diunggah customer) -- tidak cocok dipakai ulang untuk kasus ini, Setting baru yang terpisah lebih tepat.

**Validasi**: dicek di endpoint upload (5.2.1) SEBELUM file diproses lebih lanjut (sebelum whitelist ekstensi maupun `Store.create!`) -- file yang melebihi batas ditolak lebih awal, tidak perlu buang waktu memproses body request yang sudah pasti akan ditolak. Ukuran dicek dari `Content-Length` request DAN dari ukuran data aktual setelah diterima (dua kali cek -- header bisa dipalsukan, jadi ukuran sungguhan tetap perlu diverifikasi setelah data diterima).

**Pagar tambahan yang TETAP hardcode, bukan Setting**: batas ATAS mutlak (mis. 20 MB) supaya admin yang tidak sengaja mengisi `chat_attachment_max_size_mb` dengan angka sangat besar (mis. 500) tidak bisa membuka celah penyalahgunaan penyimpanan server -- pola pagar-di-atas-Setting yang sama dipakai `MAX_PER_PAGE` di `Report::ItemsPaginator` (Fase 1).

**Lokasi Admin UI**: tab "Live Chat" di Admin > Settings > SISKA (sama seperti 5.2.4a), dibuat saat implementasi.

#### 5.2.3 Perubahan UI

- **Widget** (`public/assets/chat/`): tombol/drag-drop attachment baru di area input, panggil endpoint 5.2.1, kirim event `chat_session_attachment` setelah sukses.
- **Panel agent** (`app/assets/javascripts/app/controllers/chat.coffee` + view `customer_chat/chat_message.jst.eco`): render pesan bertipe attachment sebagai link download/thumbnail -- pakai ulang styling attachment yang sudah ada di app (ikon `paperclip`, dll, BUKAN styling baru dari nol) supaya konsisten secara visual dengan attachment tiket biasa.

#### 5.2.4 Keputusan Final (Keamanan)

- **Whitelist tipe file SELALU aktif** (baseline, tidak bergantung ClamAV) -- daftarnya sekarang **configurable lewat Setting** (lihat 5.2.4a di bawah), bukan hardcode. SELALU tolak tipe executable/script (`exe/sh/bat/js/html`, dst) apa pun konfigurasinya -- pagar ini TIDAK bisa dilonggarkan lewat Setting.
- **Batas ukuran file per upload SEKARANG juga configurable lewat Setting** (`chat_attachment_max_size_mb`, lihat 5.2.2a) -- default 5 MB, dengan pagar batas atas mutlak yang tetap hardcode.
- Jumlah maksimum attachment per sesi chat -- 5 file per sesi, titik awal (belum dijadikan Setting -- bisa menyusul kalau memang dibutuhkan nanti).

#### 5.2.4a Setting untuk Daftar Tipe File yang Diizinkan

Atas permintaan user, daftar whitelist (5.2.4) dibuat jadi Setting, bukan angka/daftar tetap di kode -- mengikuti pola yang sama dipakai `aux_status_options`/`report_preview_per_page` sepanjang proyek ini (Setting sebagai satu-satunya sumber kebenaran, dibaca backend saat validasi).

**Setting baru**: `chat_attachment_allowed_extensions` (`frontend: false`, cuma dibaca backend saat validasi upload) -- string berisi daftar EKSTENSI dipisah koma, mis. `jpg,jpeg,png,gif,webp,pdf,doc,docx,xls,xlsx`. Dipilih format teks-koma-sederhana (BUKAN JSON/array, dan BUKAN editor baris seperti `aux_status_options`) -- karena ini cuma satu daftar string datar, tidak ada pasangan value/label/durasi seperti AUX Status, jadi textarea/text-input biasa (`App.UiElement.textarea`/`input` generik) sudah cukup ramah tanpa perlu UI kustom.

**Validasi 2 lapis, BUKAN cuma baca Setting mentah-mentah**:
1. **Denylist keras di kode, tidak bisa di-override Setting apa pun** -- daftar kecil ekstensi berbahaya (`exe, bat, cmd, sh, ps1, js, html, htm, php, jar, msi, com, scr, vbs`, dst) SELALU ditolak lebih dulu, SEBELUM Setting dicek sama sekali. Ini mencegah kesalahan konfigurasi (admin tidak sengaja mengetik `exe` ke dalam Setting) tetap membuka celah keamanan nyata.
2. **Baru setelah lolos poin 1**, ekstensi file dicocokkan ke `chat_attachment_allowed_extensions`. Kalau tidak ada di daftar itu, ditolak dengan pesan jelas (bukan diam-diam gagal).

**Lokasi di Admin UI**: tab "Live Chat" baru di Admin > Settings > SISKA (mengikuti pola tab-per-fase yang sudah ada: AUX Status, Reporting, Overview, dst, `_manage/siska_settings.coffee`) -- ditambahkan saat implementasi Item 5/6, belum ada tab-nya sekarang karena belum ada Setting Fase 5 yang benar-benar dibuat (baru desain).
- **Pemindaian ClamAV -- OPSIONAL, plug-and-play** (lihat 5.2.5) -- user bertanya apakah bisa dipindai ClamAV. Dicek dulu kondisi server sebelum menjawab: **RAM tersedia cuma ~1,9 GB dari 7,5 GB total, disk sudah 96% penuh (6,3 GB sisa dari 130 GB)** -- `clamd` butuh ~1-1,5 GB RAM cuma untuk memuat database signature, jadi memasangnya SEKARANG di server ini berisiko menekan sumber daya yang sudah ketat. Keputusan: **bangun dulu integrasinya dalam kondisi TIDAK AKTIF/no-op** (dikontrol lewat Setting, defaultnya kosong = mati) supaya begitu ClamAV benar-benar tersedia (di server ini setelah upgrade kapasitas, atau di server terpisah), mengaktifkannya cukup isi 2 Setting, TANPA perlu perubahan kode maupun deploy ulang.

#### 5.2.5 Desain Integrasi ClamAV (Plug-and-Play)

**Prinsip desain**: whitelist tipe file (5.2.4) adalah baseline yang SELALU jalan, tidak pernah bergantung ClamAV -- ClamAV cuma LAPISAN TAMBAHAN di atasnya. Kalau belum dikonfigurasi, sistem berperilaku PERSIS seperti tanpa fitur ini sama sekali (tidak ada perubahan perilaku, tidak ada percobaan koneksi yang menggantung/lambat).

**2 Setting baru** (`frontend: false`, cuma dibaca backend):
- `chat_attachment_clamav_host` -- default KOSONG. Kosong = pemindaian nonaktif.
- `chat_attachment_clamav_port` -- default `3310` (port standar `clamd`).

**Service class baru** `Service::Chat::VirusScan` (nama final ditentukan saat implementasi):

```ruby
module Service::Chat::VirusScan
  # Return: :skipped (tidak dikonfigurasi), :clean, :infected, :unavailable (dikonfigurasi tapi tidak bisa dihubungi)
  def self.scan(data)
    host = Setting.get('chat_attachment_clamav_host')
    return :skipped if host.blank?

    port = Setting.get('chat_attachment_clamav_port').presence || 3310

    begin
      socket = TCPSocket.new(host, port, connect_timeout: 5)
      socket.write("zINSTREAM\0")
      # protokol INSTREAM ClamAV: kirim potongan data diawali panjang 4-byte big-endian,
      # diakhiri potongan panjang 0 sebagai penanda selesai
      data.each_slice(8192) do |chunk|
        socket.write([chunk.bytesize].pack('N'))
        socket.write(chunk)
      end
      socket.write([0].pack('N'))
      response = socket.gets
      socket.close

      return :infected if response&.include?('FOUND')
      return :clean if response&.include?('OK')

      :unavailable
    rescue => e
      Rails.logger.error "ClamAV scan gagal: #{e.message}"
      :unavailable
    end
  end
end
```

**Kebijakan fail-safe -- SENGAJA fail-CLOSED, bukan fail-open**: kalau admin SUDAH mengisi `chat_attachment_clamav_host` (artinya mereka SUDAH memutuskan pemindaian ini wajib), tapi `clamd` ternyata tidak bisa dihubungi saat upload terjadi (`:unavailable`), upload DITOLAK dengan pesan error -- BUKAN diam-diam diloloskan tanpa pemindaian. Alasan: begitu seseorang secara eksplisit mengaktifkan proteksi ini, kegagalan diam-diam yang melewatkannya lebih berbahaya daripada penolakan upload yang terlihat jelas oleh customer (yang bisa coba lagi nanti). Beda dengan kondisi `:skipped` (belum dikonfigurasi sama sekali) yang memang sengaja tidak memindai apa pun -- itu bukan kegagalan, itu keadaan default yang disengaja.

**Titik pemasangan** di alur upload (5.2.2): dipanggil SETELAH validasi whitelist tipe/ukuran file lolos, SEBELUM `Store.create!`. Kalau `:infected` atau `:unavailable` (dan dikonfigurasi), upload ditolak dengan pesan berbeda untuk masing-masing (biar customer/agent tahu apakah file-nya bermasalah atau layanan pemindainya yang sedang gangguan).

**Docker Compose -- disiapkan sebagai referensi, BELUM diaktifkan** (menghindari menambah beban server sekarang sesuai keputusan 5.2.4):

```yaml
# Tambahkan service ini ke docker-compose.yml KAPAN PUN ClamAV siap dipasang
# (di server ini setelah upgrade kapasitas, atau arahkan host/port ke server
# terpisah yang sudah punya ClamAV -- tidak harus container di compose yang sama).
  clamav:
    image: clamav/clamav-debian:stable
    restart: unless-stopped
    # butuh ~1-1.5 GB RAM untuk database signature -- pastikan kapasitas cukup
    # sebelum mengaktifkan (lihat catatan kapasitas server di Section 5.2.4).
```

**Jadi "plug-and-play"-nya secara konkret**: begitu container/server ClamAV tersedia (di mana pun), isi `chat_attachment_clamav_host`/`_port` lewat Admin Settings -- TIDAK ada kode yang perlu diubah, TIDAK ada deploy ulang. `Service::Chat::VirusScan.scan` otomatis mulai memindai upload berikutnya. Untuk mematikan lagi, cukup kosongkan `chat_attachment_clamav_host`.

### 5.3 Fitur Tambahan: Reply ke Pesan Spesifik (Seperti WhatsApp)

Atas permintaan user -- fitur baru di jendela chat (BUKAN bagian Item 5/6 dari Gap Analysis awal, tapi tambahan langsung untuk pengalaman chat itu sendiri), berlaku untuk KEDUA sisi (widget customer & panel agent), karena keduanya berbagi konsep "pesan" yang sama.

#### Skema

Dicek dulu `chat_messages` (Section 3.1) -- cuma `content`/`created_by_id`, tidak ada kolom referensi-diri. Ditambahkan:

```ruby
add_column :chat_messages, :reply_to_id, :integer, null: true
add_foreign_key :chat_messages, :chat_messages, column: :reply_to_id
```

Dipilih kolom FK asli (BUKAN dititip ke kolom preferences seperti pola `chat_sessions`) -- ini relasi 1-ke-1 yang jelas & sederhana (satu pesan me-reply SATU pesan lain), tidak butuh fleksibilitas JSON, dan FK asli membuat Rails `belongs_to :reply_to, class_name: 'Chat::Message'` jalan langsung tanpa parsing manual.

#### Backend: `ChatSessionMessage`

`lib/sessions/event/chat_session_message.rb#run` (dibaca detail lengkapnya saat menulis desain ini) SAAT INI cuma terima `content` dari payload. Diubah:

1. Terima `reply_to_id` opsional dari `@payload['data']['reply_to_id']`.
2. **Validasi keamanan**: kalau diisi, PASTIKAN pesan yang direferensikan (`Chat::Message.find_by(id: reply_to_id)`) benar-benar milik `chat_session` YANG SAMA (`reply_to.chat_session_id == chat_session.id`) -- mencegah satu sesi chat mereferensikan/membocorkan potongan pesan dari sesi chat ORANG LAIN lewat id yang ditebak/dimanipulasi. Kalau tidak cocok, `reply_to_id` diabaikan (pesan tetap terkirim, cuma tanpa quote) -- bukan menolak seluruh pesan.
3. `Chat::Message.create(chat_session_id:, content:, created_by_id:, reply_to_id:)`.
4. Broadcast (ke customer & agent, kode yang sudah ada di `run` cukup diteruskan apa adanya karena `chat_message` di-serialize utuh) -- TAMBAHAN: eager-load `reply_to` dan sertakan isinya (content + pengirim) inline di payload, supaya penerima tidak perlu query/lookup terpisah untuk menampilkan potongan kutipan -- konten pesan tidak pernah diedit di chat ini (tidak ada fitur edit pesan), jadi menyertakan salinan konten saat itu juga TIDAK berisiko basi/tidak sinkron.

#### UI -- Widget Customer & Panel Agent (Perubahan Paralel)

Karena kedua sisi (`public/assets/chat/`, `app/assets/javascripts/app/controllers/chat.coffee`) punya markup pesan yang SANGAT flat sekarang (dicek langsung -- `views/message.eco` widget dan `customer_chat/chat_message.jst.eco` agent SAMA-SAMA cuma 1 `<div>` per pesan, tidak ada wrapper metadata sama sekali), 3 penyesuaian yang SAMA perlu dibuat di KEDUA tempat:

1. **Affordance reply** -- ikon/tombol muncul saat hover (agent, desktop) atau tap-and-hold (customer, mobile-friendly) di sebuah bubble pesan, memicu "mode balas".
2. **Indikator "membalas..."** di atas kotak input -- potongan singkat (mis. 80 karakter pertama) dari pesan yang direply + tombol batal (×). Dikirim bersama `content` sebagai `reply_to_id` saat pesan baru disubmit.
3. **Render kutipan di bubble pesan baru** -- kalau `message.reply_to` ada, tampilkan blok kutipan kecil (gaya WhatsApp: garis vertikal + teks pudar) di ATAS isi pesan, sebelum konten pesan itu sendiri. Opsional/nice-to-have: tap pada kutipan men-scroll ke pesan asli (butuh pesan asli masih ada di DOM/scroll buffer saat ini -- untuk chat yang sangat panjang, pesan lama mungkin sudah di luar buffer yang dimuat, jadi scroll-to bisa gagal senyap kalau begitu; bukan blocker, cuma diterima sebagai keterbatasan kecil).

**Catatan cakupan**: ini menambah SATU LAGI perubahan yang menyentuh 2 codebase terpisah (widget + app utama, lihat peringatan Item 6 Section 3.3/3.5) -- pola risiko yang sama, bukan yang baru.

#### Integrasi ke Sinkronisasi Tiket (5.1.4)

Kalau sesi chat terhubung ke tiket (Item 5), pesan yang di-relay jadi `Ticket::Article` (5.1.4) dan merupakan balasan ke pesan lain: body artikel diberi prefix blockquote berisi kutipan pesan asli sebelum isi balasannya -- pola blockquote-kutipan yang SAMA sudah dipakai proyek ini di halaman feedback CSAT (Fase 1, `docs/DESIGN_FEEDBACK_RATING.md`) untuk mengingatkan isi keluhan asli tiket. Supaya orang yang MEMBACA TIKET SAJA (tanpa buka jendela chat) tetap paham konteks balasan, bukan cuma teks lepas tanpa rujukan.

---

*Section 1-4: riset & keputusan terbuka. Section 5: desain teknis rinci, ditulis setelah keputusan Section 4 didapat dari user. Pertanyaan terbuka di 5.1.6/5.2.4 sebaiknya dijawab (atau sengaja dilewati dengan default yang diusulkan) sebelum implementasi kode dimulai.*
