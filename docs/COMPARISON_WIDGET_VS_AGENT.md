# Komparasi Fitur Jendela Chat: Widget Customer vs Panel Agent

Disusun 2026-09-25 dari kode `HEAD` (setelah commit `71047e60`):

- **Widget customer:** `public/assets/chat/chat-no-jquery.coffee`, `views/*.eco`, `chat.scss`.
- **Panel agent:** `app/assets/javascripts/app/controllers/chat.coffee`,
  `views/customer_chat/siska_*.jst.eco`, `app/assets/stylesheets/siska_agent_chat.scss`.

Tujuan: menandai fitur yang ada di satu sisi tetapi tidak di sisi lain.
Status berdasarkan pembacaan kode, belum diuji di browser. Gap (G1–G8) masuk
backlog **Fase Regresi Zammad vs Tailwind** (lihat `docs/INVENTORY_AGENT_CHAT.md`
bagian 5).

Legenda: ✅ setara · ◐ berbeda tapi wajar / disengaja · ❗ gap

## 1. Bubble & pesan

| Fitur | Widget customer | Panel agent | Status |
|---|---|---|---|
| Letak jam | Di dalam bubble, pojok kanan bawah | Di atas bubble, bersama nama pengirim | ◐ Beda gaya sesuai mockup masing-masing |
| Tanda terkirim/dibaca | Pesan customer: centang abu → biru saat agent membaca | **Tidak ada**; agent tidak tahu apakah customer sudah membaca. `chat_session_message_read.rb` hanya menerima event dari agent (menandai pesan customer) | ❗ **G1** |
| Tanda belum dibaca | Pesan ditandai saat tab tidak aktif + suara | Angka belum dibaca di kartu daftar + suara + notifikasi desktop | ✅ |
| Indikator mengetik | Ada | Ada | ✅ |
| Kutipan reply di bubble | Ada | Ada | ✅ |

## 2. Menu pesan & reaksi

| Fitur | Widget customer | Panel agent | Status |
|---|---|---|---|
| Menu muncul di | Hanya pesan agent | Semua pesan (kecuali riwayat) | ◐ |
| Reply | Ada, hanya ke pesan agent | Ada, ke semua pesan | ◐ |
| Copy teks | Ada + toast "Copied" (`copyMessage`) | **Tidak ada** | ❗ **G2** |
| Download lampiran | Ada | Ada | ✅ |
| Reaksi emoji | Customer bereaksi (5 emoji whitelist) ke pesan agent | Agent hanya **melihat** chip reaksi; tidak bisa bereaksi. Backend `chat_session_reaction.rb` menolak event dari sesi agent | ❗ **G3** (satu arah) |

## 3. Gambar & file

| Fitur | Widget customer | Panel agent | Status |
|---|---|---|---|
| Ukuran pratinjau gambar | `width: 100%`, `height: auto`, `max-height: 280px` → tidak seragam | Seragam 240 × 180, crop penuh (`d3dff1bf`) | ❗ **G4** |
| Kartu gambar (nama, tipe · ukuran, unduh) | Tidak ada; jam + centang ditumpuk di atas gambar | Ada, putih bergaris (`71047e60`) | ❗ **G5** |
| Kartu file per tipe | Ada, warna per tipe | Ada, pemetaan & warna sama (`App.SiskaIcon`) | ✅ |
| Viewer layar penuh | Ada | Ada | ✅ |
| Progress unggah | Placeholder + bar persen (`updateImageUpload`) | Placeholder + bar persen, diganti di posisinya oleh pesan asli | ✅ **G6 selesai** (2026-09-25) |
| Tempel / seret gambar ke kotak ketik | Paste & drop | Lewat editor rich text Zammad | ✅ |

## 4. Area ketik

| Fitur | Widget customer | Panel agent | Status |
|---|---|---|---|
| Emoji picker | 18 emoji | 18 emoji (set sama) | ✅ |
| Kirim gambar / lampirkan file | Ada | Ada ("Attach" selalu kartu file di keduanya) | ✅ |
| Text module (`::`) | — | Ada | ◐ Khusus agent |
| Pesan belum terkirim tersimpan saat reload | Ada (`unfinished_message`) | Tidak ada | ◐ Kecil |

## 5. Sesi & riwayat

| Fitur | Widget customer | Panel agent | Status |
|---|---|---|---|
| Riwayat chat lama di jendela | Tidak ada; tab Messages hanya percakapan saat ini | Ada, 10 pesan per halaman + paging (`4d574940`) | ◐ **Disengaja**: customer anonim hanya dikenali dari email yang diketik sendiri; riwayat per email tanpa verifikasi bisa membocorkan chat orang lain |
| Sapaan pembuka / penutup | Sapaan selamat datang & penutup (phrase admin) | Sapaan otomatis per topik (Settings agent) | ✅ Saling melengkapi |
| Rating | Customer memberi rating | Agent melihat rating (Setting `chat_agent_show_rating`, default menyala) | ✅ |
| Chat berakhir | Layar penutup + rating | Pemisah, kartu rating, bilah "percakapan telah berakhir" | ✅ |
| Status koneksi | Overlay "Connection lost" + reconnect otomatis | Tidak ada penanda putus koneksi di jendela chat (hanya reconnect bawaan Zammad) | ❗ **G7** |

## 6. Bahasa

| Fitur | Widget customer | Panel agent | Status |
|---|---|---|---|
| Bahasa label | Indonesia, dari phrase server (diatur admin) | English (string sumber `@T`, locale agent English) | ❗ **G8** |

## 7. Backlog gap

| # | Gap | Sisi yang kurang | Usulan |
|---|---|---|---|
| G1 | Tanda terkirim/dibaca untuk pesan agent | Agent (+ backend) | Widget mengirim `chat_session_message_read` saat customer melihat pesan; backend menerimanya dari sesi customer; agent menampilkan centang |
| G2 | Copy teks pesan | Agent | Item "Copy" di menu titik tiga |
| G3 | Reaksi emoji dari agent | Agent (+ backend + widget) | **Putuskan dulu** perlu/tidak; bila perlu, backend menerima reaksi dari agent & widget menampilkannya |
| G4 | Pratinjau gambar seragam 240 × 180 | Widget | Terapkan aturan yang sama |
| G5 | Kartu gambar | Widget | Terapkan, atau putuskan tetap ringkas di widget yang sempit |
| G6 | Progress unggah dengan persen | Agent | ✅ **Selesai** 2026-09-25, bersama perbaikan B1 |
| G7 | Penanda putus koneksi di jendela chat | Agent | Banner "Connection lost, reconnecting…" terhubung ke status `App.WebSocket` — **direvisi di audit (bagian 8): lebih kecil** |
| G8 | Bahasa label panel agent | Agent | Terjemahan Bahasa Indonesia untuk string baru — **direvisi di audit (bagian 8): locale `id` belum aktif** |

## 8. Hasil audit G1–G8 (2026-09-25)

Setiap gap diperiksa ulang ke kode (termasuk bawaan Zammad). Dua gap
**direvisi** (G7, G8) dan satu **bug baru** ditemukan saat mengaudit G6.
Ukuran: S = kecil, M = sedang, L = besar.

| # | Hasil verifikasi | Akar masalah & perubahan yang dibutuhkan | Ukuran | Prioritas |
|---|---|---|---|---|
| G1 | Terkonfirmasi | Kolom `chat_messages.read_at` sudah ada, tetapi hanya diisi untuk pesan customer; `chat_session_message_read.rb` menolak pengirim non-agent (`return if !@session`). **Backend:** jalur customer (cek participant seperti `chat_session_reaction.rb`) yang menandai pesan agent + field `reader` di broadcast. **Widget:** kirim event saat pesan agent benar-benar terlihat (panel terbuka, tab aktif, dokumen tidak tersembunyi); abaikan broadcast yang berasal dari tab customer lain. **Agent:** centang terkirim/dibaca di bubble agent, kondisi awal dari `read_at` (percakapan & riwayat) | M | Tinggi |
| G2 | Terkonfirmasi | Hanya frontend agent: item "Copy" di menu titik tiga, `navigator.clipboard.writeText` + fallback, notifikasi "Copied" | S | Sedang |
| G3 | Terkonfirmasi, **butuh keputusan** | `customer_reaction` hanya berlaku untuk pesan agent. Reaksi agent ke pesan customer butuh kolom baru (migrasi, mis. `agent_reaction`), backend menerima reaksi dari sesi agent, chip reaksi di bubble customer pada widget, emoji di menu agent | M–L | Rendah (kecuali diinginkan) |
| G4 | Terkonfirmasi | Widget: `.zammad-chat-image-open` lebar 220px, `.zammad-chat-image-thumb` `height: auto` (min 120px, maks 280px) → tinggi berubah-ubah. Cukup CSS + placeholder unggah berukuran sama. Panel widget 380px → **keputusan ukuran**: 240 × 180 (sama dgn agent) atau 220 × 165 (menyesuaikan lebar bubble widget) | S | Sedang |
| G5 | Terkonfirmasi, **tarik-menarik desain** | Widget menumpuk jam + centang biru di atas gambar (gaya WhatsApp). Kartu berarti memindahkannya ke kaki kartu; di panel sempit nama file gambar kiriman sendiri kurang berguna | M | Butuh keputusan |
| G6 | Terkonfirmasi + **bug** | `App.Ajax.request` meneruskan parameter apa adanya ke `$.ajax`, jadi opsi `xhr` (`upload.onprogress`) bisa dipakai → placeholder dgn bar persen seperti widget. **Bug (B1):** upload memakai `id: 'chat-attachment-upload'` tetap, `@ajax` meneruskannya tanpa awalan per jendela, dan `App.Ajax.request` memanggil `@abort(id)` untuk request lama ber-id sama secara global → upload di satu jendela chat agent membatalkan upload yang masih berjalan di jendela chat lain (di `App.MyChat` juga dua upload berturut-turut di jendela yang sama). Di jendela agent yang sama tidak terjadi karena tombol lampiran nonaktif selama upload. Akibat: file tidak terkirim & agent hanya melihat dialog umum "The attachment could not be uploaded." | S–M | **Tinggi** (karena B1) |
| G7 | **Direvisi: lebih kecil** | Zammad sudah menampilkan modal global "Lost network connection! Trying to reconnect…" 7 detik setelah koneksi putus (`websocket.coffee`), dan `App.WebSocket.send` **mengantrekan** pesan selama putus lalu mengirimnya saat tersambung → tidak ada pesan yang hilang. Sisa gap kosmetik: 7 detik pertama tanpa penanda, modal menutup seluruh layar | S | Rendah |
| G8 | **Direvisi: lebih besar** | Locale Indonesia **belum aktif** (`Locale` aktif tidak memuat `id`; 0 baris `Translation` untuk `id`); semua agent `en-us`. `i18n/zammad.id.po` sudah 96% (4.104 / 4.261 string). Menerjemahkan label chat saja tidak berefek selama agent memakai locale English | M | Butuh keputusan |

### Keputusan yang dibutuhkan

1. **G3:** perlukah agent bisa bereaksi ke pesan customer?
2. **G4:** ukuran gambar widget 240 × 180 atau 220 × 165?
3. **G5:** widget memakai kartu gambar, atau tetap gaya WhatsApp (jam + centang di atas gambar)?
4. **G8:** (a) aktifkan locale Indonesia + terjemahkan string baru redesign (**usulan**), atau (b) tulis langsung Bahasa Indonesia di panel chat saja (lebih cepat, mematikan i18n, tidak konsisten dgn bagian Zammad lain).

### Urutan kerja yang diusulkan

1. G6 + perbaikan B1 (upload paralel)
2. G2
3. G1
4. G4 (setelah ukuran diputuskan)
5. G8, G5, G3 (setelah diputuskan)
6. G7
