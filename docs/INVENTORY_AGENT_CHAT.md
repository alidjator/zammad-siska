# Inventaris Fitur Panel Chat Agent (sebelum vs sesudah redesign)

Disusun 2026-09-24, **setelah** redesign Tahap 0–4 dikerjakan (inventaris
seharusnya dibuat sebelum Tahap 0; dibuat retroaktif atas permintaan user).

- **Baseline (sebelum redesign):** commit `1524128e`, berkas
  `app/assets/javascripts/app/controllers/chat.coffee`,
  `app/assets/javascripts/app/views/customer_chat/*`,
  `app/assets/javascripts/app/controllers/customer_chat/image_view.coffee`.
- **Sesudah:** Tahap 0 `efde8f9f`, Tahap 1 `e368742e`, Tahap 2 `8d8cd9e3`,
  Tahap 3 `060ea820`, Tahap 4 (belum di-commit saat dokumen ini dibuat).
- **Di luar cakupan:** `App.MyChat` (chat follow-up user login,
  `my_chat.coffee`) tetap memakai `ChatWindow` varian lama
  (`chat_window.jst.eco` asli) — tidak ikut berubah.

Legenda status:

| Status | Arti |
|---|---|
| ✅ Tetap | Perilaku sama, hanya tampilan yang mungkin berubah |
| 🔄 Berubah | Fitur masih ada, bentuk/interaksinya berbeda |
| ❌ Hilang | Fitur lama tidak ada lagi di desain baru |
| ⚠️ Regresi | Masih ada, tetapi ada kasus yang tidak lagi berjalan seperti dulu |
| ➕ Baru | Tidak ada di baseline, ditambahkan selama redesign |

---

## 1. Halaman & status agent (`App.CustomerChat`)

| # | Fitur lama | Kode baseline | Status | Catatan / tindakan |
|---|---|---|---|---|
| 1.1 | Judul halaman "Customer Chat" | `index.jst.eco` | ✅ | Gaya kit |
| 1.2 | Tombol **Settings** membuka modal pengaturan | `'click .js-settings'` | ✅ | Modal masih lama, diganti di Tahap 5 |
| 1.3 | Toggle Online/Offline di navigasi kiri (`switch`) | `switch:` via `_plugin/navigation.coffee` | ✅ | Ditambah switch di header, tersinkron dua arah |
| 1.4 | Saat Online tanpa topik aktif: 1 topik → aktif otomatis; >1 topik → modal Settings terbuka dengan pesan error | `switch:` | ✅ | Kode tidak diubah |
| 1.5 | Push state tiap 55 detik (`chat_agent_state`) | `startPushState` | ✅ | |
| 1.6 | **Idle timeout**: antrean tidak dijawab `chat_agent_idle_timeout` detik → otomatis Offline + notifikasi | `idleTimeoutStart` | ✅ | |
| 1.7 | Badge jumlah di navigasi (menunggu + belum dibaca) | `counter:` | ✅ | |
| 1.8 | Suara `chat_new` + notifikasi desktop saat ada customer menunggu | `counter:` | ✅ | |
| 1.9 | Re-render saat ganti bahasa (`ui:rerender`) | constructor | ✅ | |
| 1.10 | Sesi aktif dipulihkan setelah reload (`active_sessions`) | `updateMeta:` | ✅ | |
| 1.11 | Kotak **Waiting Customers** + jumlah, berdenyut (`pulsate-animation`) saat ada antrean & kapasitas masih ada | `chat_header.jst.eco`, `updateMeta:` | 🔄 | Jadi bagian "Waiting for agent" di kartu daftar + tombol **Accept next**. Animasi denyut **hilang** (kosmetik) |
| 1.12 | >1 topik: dropdown "Waiting in *topik*", terima per topik | `chat_header.jst.eco` | 🔄 | Satu tombol Accept next per topik |
| 1.13 | Terima chat = FIFO (customer terlama) | `acceptChat:` → `chat_session_start` | ✅ | Keputusan user: tetap FIFO |
| 1.14 | Accept dinonaktifkan kalau jendela ≥ `max_windows` | `acceptChat:` | ✅ | Jendela chat berakhir yang belum ditutup **tetap dihitung**, sama seperti dulu |
| 1.15 | **Popover Waiting Customers**: nama sesi, GeoIP, jam masuk | `chatSessionList`, `chat_list.jst.eco` | 🔄 | Daftar tunggu menampilkan nama, kategori, lama menunggu. **GeoIP antrean hilang** |
| 1.16 | **Popover Chatting Customers**: semua chat berjalan (termasuk milik agent lain) + nama agent yang melayani | `running_chat_session_list` | ❌ | Sekarang hanya angka "N in progress" milik agent sendiri. **Keputusan dibutuhkan** |
| 1.17 | **Popover Active Agents**: daftar agent aktif dengan avatar | `user_list.jst.eco` | 🔄 | Jadi angka + tooltip nama agent di ringkasan header (tanpa avatar) |
| 1.18 | Buka sesi lewat URL `#customer_chat/session/:id` | `show:` | ⚠️ | Sesi dibuka, tetapi **tidak otomatis dipilih** kalau agent sedang melihat chat lain / sesi sudah terbuka. **Perlu diperbaiki** |
| 1.19 | Beberapa jendela chat tampil berjajar (maks. 4) | `.chat-workspace` flex | 🔄 | Sengaja diganti pola daftar + detail (mockup) |
| 1.20 | Tata letak ponsel: geser horizontal antar jendela | `zammad.scss` `@include phone` | 🔄 | Daftar di atas (40vh) + detail di bawah. **Belum diuji di ponsel** |

## 2. Jendela percakapan (`App.ChatWindow`)

| # | Fitur lama | Kode baseline | Status | Catatan / tindakan |
|---|---|---|---|---|
| 2.1 | Indikator status sesi (titik hijau/merah) | `.js-status` | 🔄 | Titik di avatar header; avatar abu setelah berakhir |
| 2.2 | Nama customer + `#id` sesi di header | `chat_window.jst.eco` | 🔄 | Nama + baris "email · kategori · session #" |
| 2.3 | Penanda **ada pesan belum dibaca** di header (`is-modified`) | `updateModified` | 🔄 | Diganti angka belum dibaca di kartu daftar |
| 2.4 | Tombol **disconnect** | `'click .js-disconnect'` | ✅ | Jadi tombol merah **End chat** |
| 2.5 | Tombol **close** setelah chat berakhir | `'click .js-close'` | ✅ | Jadi **Remove from list** di bilah chat berakhir |
| 2.6 | Klik nama → panel meta menggantikan isi percakapan | `toggleMeta` | 🔄 | Panel **Profile & history** di kanan, percakapan tetap terlihat |
| 2.7 | Meta: **transfer** ke topik lain | `js-transferChat` | ✅ | Tombol ikon Transfer (tersembunyi bila tidak ada topik lain) |
| 2.8 | Meta: **Created at** (tanggal + jam) | `@Ttimestamp(session.created_at)` | ⚠️ | Hanya jam untuk sesi hari ini; sesi dari hari lain tampil tanggal saja. Detail jam-tanggal lengkap hilang. **Kecil** |
| 2.9 | Meta: tautan **Open Ticket** selama chat berjalan | `js-openPreviousTicket` | ✅ | Tombol ikon Tiket + baris Ticket (nomor tiket) |
| 2.10 | Meta: **riwayat chat sebelumnya** + transkrip lengkap (`<details>`) | `previous_sessions` | ✅ | Kartu riwayat + agent, cuplikan, rating, nomor tiket; transkrip tetap bisa dibuka |
| 2.11 | Meta: **GeoIP** | `preferences.geo_ip` | ✅ | Baris Location |
| 2.12 | Meta: **IP** | `preferences.remote_ip` | ✅ | |
| 2.13 | Meta: **DNS name** | `preferences.dns_name` | ❌ | **Hilang**, mudah dikembalikan |
| 2.14 | Meta: form **Name** & **Tags** (`chat_session_update`) | `js-metaForm`, `sendMetaForm` | ✅ | Dilipat di panel. Disimpan saat panel ditutup / chat ditutup (dulu juga tiap kirim pesan) |
| 2.15 | URL halaman asal customer di awal percakapan | `addNoticeMessage(preferences.url)` | ✅ | |
| 2.16 | Pemisah waktu "today HH:MM" tiap 2 menit | `maybeAddTimestamp` | ✅ | Berbentuk pil |
| 2.17 | Pesan notice server (`chat_session_notice`) | constructor | ✅ | |
| 2.18 | Status "X left/closed the conversation" | `chat_session_left/closed` | 🔄 | Pemisah bergaris "Chat ended by … · jam" |
| 2.19 | Kirim pesan dengan **Enter**, baris baru Shift+Enter | `onKeydown` | ✅ | |
| 2.20 | **Tab** pindah antar kotak ketik jendela lain | `onKeydown` TABKEY | 🔄 | Tidak relevan lagi (hanya satu jendela tampil) |
| 2.21 | Event **mengetik** ke customer (throttle 1,4 dtk) | `chat_session_typing` | ✅ | |
| 2.22 | Indikator **customer sedang mengetik** | `showWritingLoader` | ✅ | Tiga titik + "X is typing…" |
| 2.23 | Editor rich text (`ce`), tempel gambar inline | `onTransitionend` | ✅ | |
| 2.24 | **Text module** (`::` di kotak ketik) | `App.WidgetTextModule` | ✅ | Kelas input sama |
| 2.25 | **Sapaan otomatis** per topik saat chat baru (acak dari daftar `;`) | `render:` phrase | ✅ | |
| 2.26 | Pesan masuk: suara + notifikasi desktop bila tidak fokus | `receiveMessage` | ✅ | |
| 2.27 | Klik notifikasi → fokus ke jendela (`chat_focus`) | constructor | ✅ | Sekaligus memilih chat di daftar |
| 2.28 | Tanda **dibaca** ke customer (`chat_session_message_read`) | `clearUnread` | ✅ | |
| 2.29 | **Reply** ke pesan (ikon di bubble) | `js-replyMessage` | 🔄 | Lewat menu titik tiga. Kini pesan agent sendiri juga bisa di-reply (dulu tidak punya id) |
| 2.30 | Indikator "Replying to…" + batal | `renderReplyIndicator` | ✅ | |
| 2.31 | Kutipan reply di bubble | `chat_message.jst.eco` | ✅ | |
| 2.32 | **Lampiran**: tombol attach (per-agent + saklar global) | `js-attachButton` | ✅ | Kini dua tombol: Send image & Attach file |
| 2.33 | Lampiran tampil sebagai **tautan nama file** + ikon download | `chat_attachment_message.jst.eco` | 🔄 | Thumbnail gambar / kartu file per tipe |
| 2.34 | Error upload → dialog | `uploadAttachment` | ✅ | + status "Uploading …" |
| 2.35 | Klik gambar di pesan → modal pratinjau + tombol Download | `App.CustomerChatImageView` | 🔄 | Viewer layar penuh. Untuk gambar **yang ditempel inline** (bukan lampiran), tombol Download **tidak ada** lagi. **Kecil** |
| 2.36 | Petunjuk "Scroll down to see new messages" | `showScrollHint` | ✅ | Gaya masih lama |
| 2.37 | Akhir chat: tombol **Open Ticket** (bila tiket otomatis sudah ada) | `chat_footer.jst.eco` | ✅ | Tombol Open ticket di bilah chat berakhir |
| 2.38 | Akhir chat: tombol **Turn chat into ticket** (bila tiket otomatis tidak dibuat) → form tiket baru terisi URL transkrip | `ticketCreate` | ❌ | **Hilang** di bilah chat berakhir. Berpengaruh bila `chat_auto_ticket_group_id` kosong / topik tanpa grup. **Perlu dikembalikan** |
| 2.39 | Animasi buka/tutup jendela (`transitionend`) | `onTransitionend`, `close` | 🔄 | Fade 150 ms; mekanisme `transitionend` dipertahankan |

## 3. Modal Settings (`class Setting`) — untuk Tahap 5

Semua ✅ saat ini (belum disentuh). Wajib dipertahankan saat diganti halaman:

| # | Isian / perilaku | Preferensi |
|---|---|---|
| 3.1 | Maks. chat bersamaan (1–20), langsung berlaku tanpa reload | `chat.max_windows` |
| 3.2 | Nama alternatif untuk customer | `chat.alternative_name` |
| 3.3 | Izinkan lampiran dari customer — **hanya tampil bila** saklar global `chat_attachment_enabled` menyala | `chat.attachment_enabled` |
| 3.4 | Avatar enabled/disabled | `chat.avatar_state` |
| 3.5 | Per topik: sapaan (dipisah `;`, placeholder memakai nama depan agent) | `chat.phrase[chat_id]` |
| 3.6 | Per topik: aktif | `chat.active[chat_id]` |
| 3.7 | Semua topik dimatikan → agent otomatis Offline | `submit:` |
| 3.8 | Pesan error di atas form (mis. dari 1.4) | `@errors.settings` |
| 3.9 | Simpan → `PUT /users/preferences`, muat ulang user, kirim `chat_status_agent` | `success:` |
| 3.10 | Error simpan → notifikasi | `error:` |

## 4. Yang baru (➕) selama Tahap 0–4

Ikon Phosphor Duotone · gaya kit · pencarian chat · cuplikan pesan terakhir
& jam di daftar · lama menunggu per customer · bagian "Recently ended" ·
banner Offline + Go online · reaksi emoji customer · pemilih emoji · kirim
gambar (thumbnail) · kartu file per tipe · viewer layar penuh · menu titik
tiga · reply ke pesan agent sendiri · nama agent / cuplikan / nomor tiket di
riwayat · rating customer (riwayat & kartu real-time, Setting
`chat_agent_show_rating`, default menyala) · bilah "percakapan telah
berakhir".

## 5. Backlog Fase Regresi "Zammad vs Tailwind"

Keputusan user (2026-09-24): temuan di bawah **dicatat dulu, tidak
diperbaiki di Tahap 4**. Semuanya ditindaklanjuti di fase tersendiri
setelah redesign selesai (Tahap 5), yaitu **Fase Regresi Zammad vs
Tailwind**: membandingkan setiap fitur baseline Zammad (bagian 1–3) dengan
implementasi gaya kit Tailwind, lalu memperbaiki yang hilang/regresi.
Hasil inventaris modal Settings (bagian 3) tetap dipakai sebagai daftar
wajib saat Tahap 5.

| # | Item | Usulan |
|---|---|---|
| 2.38 | Turn chat into ticket hilang | **Kembalikan** di bilah chat berakhir (tombol "Create ticket" bila belum ada tiket) |
| 1.18 | Buka sesi lewat URL tidak memilih sesinya | **Perbaiki** (bug) |
| 2.13 | DNS name hilang | **Kembalikan** di baris detail panel profil |
| 2.8 | Tanggal+jam mulai sesi | **Perbaiki**: tampilkan tanggal + jam bila bukan hari ini |
| 1.16 | Daftar chat berjalan milik semua agent hilang | **Keputusan user**: kembalikan (mis. tooltip/popover di ringkasan "N in progress") atau sengaja dibuang |
| 1.15 | GeoIP di daftar tunggu | Opsional: tambahkan sebagai baris kecil di item antrean |
| 1.17 | Avatar agent aktif | Opsional: popover kecil daftar agent aktif |
| 2.35 | Download gambar inline di viewer | Opsional: tombol Download memakai `src` gambar |
| 1.11 | Animasi denyut Accept | Opsional (kosmetik) |
| 1.20 | Tata letak ponsel | **Uji** di perangkat |

### Tambahan backlog: komparasi widget customer vs panel agent (2026-09-25)

Sumber: `docs/COMPARISON_WIDGET_VS_AGENT.md` bagian 7.

| # | Item | Usulan |
|---|---|---|
| G1 | Tanda terkirim/dibaca untuk pesan agent tidak ada | ✅ **Selesai** 2026-09-25 |
| G2 | Copy teks pesan tidak ada di agent | ✅ **Selesai** 2026-09-25 |
| G3 | Reaksi emoji hanya satu arah (customer → agent) | ✅ **Selesai** 2026-09-25 (keputusan user: perlu) |
| G4 | Pratinjau gambar di widget belum seragam 240 × 180 | ✅ **Selesai** 2026-09-25 |
| G5 | Kartu gambar belum ada di widget | ✅ **Selesai** 2026-09-25 |
| G6 | Progress unggah agent tanpa persen | ✅ **Selesai** 2026-09-25 |
| G7 | Tidak ada penanda putus koneksi di jendela chat agent | ✅ **Selesai** 2026-09-25: event `ws:connection` + banner di halaman chat |
| G8 | Label panel agent masih English | ✅ **Selesai** 2026-09-25: locale `id` + `i18n/siska.id.po`. Production: buat record locale `id` dari `config/locales.yml` lalu `Translation.sync_locale_from_po('id')` |
| B1 | **Bug**: upload lampiran bisa membatalkan upload lain. `chat.coffee` memakai `id: 'chat-attachment-upload'` tetap; `@ajax` meneruskannya tanpa awalan per jendela (`_base.coffee`), dan `App.Ajax.request` memanggil `@abort(id)` untuk request lama ber-id sama secara global (`ajax.coffee`). **Terjadi:** antar jendela chat agent (upload di chat A, pindah ke chat B & upload sebelum A selesai → upload A batal diam-diam), dan di `App.MyChat` untuk dua upload berturut-turut di jendela yang sama. **Tidak terjadi** di jendela agent yang sama (tombol lampiran nonaktif selama upload). **Akibat:** file tidak terkirim & tidak tersimpan di tiket; agent hanya melihat dialog umum "The attachment could not be uploaded." | ✅ **Selesai** 2026-09-25: id unik per upload `chat-attachment-upload-<session_id>-<nomor>` (juga untuk `App.MyChat`). Detail: `docs/COMPARISON_WIDGET_VS_AGENT.md` bagian 8 |
| B2 | Pil waktu jendela agent ("today HH:MM") memakai jam saat jendela dirender (mis. saat hard refresh), bukan jam pesan pertama -- perilaku lama `maybeAddTimestamp` | ✅ **Selesai** 2026-09-25: pil memakai `created_at` pesan (tanggal utk hari lain) |
| B3 | Baris URL halaman asal muncul dua kali di jendela agent setelah halaman customer dimuat ulang (notice `chat_session_notice` + URL awal sesi) | ✅ **Selesai** 2026-09-25: notice sama dgn notice terakhir dilewati (A → B → A tetap tercatat) |
| G9 | Widget: pesan customer sendiri tanpa menu Reply / Copy / Download (ditemukan 2026-09-25) | ✅ **Selesai** 2026-09-25: menu ▾ di pesan sendiri (Reply + Copy / Download, tanpa reaksi) |
| K1 | Kartu gambar agent vs widget belum identik: lebar (agent 240 termasuk garis → gambar 238 px), warna garis (#e7eaee vs #e8ebee), padding kaki kartu, tinggi baris | ✅ **Selesai** 2026-09-25: 13 properti CSS kartu identik |
