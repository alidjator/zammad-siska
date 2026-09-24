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
| Progress unggah | Placeholder + bar persen (`updateImageUpload`) | Hanya teks "Uploading …" tanpa persen | ❗ **G6** |
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
| G6 | Progress unggah dengan persen | Agent | Samakan dengan widget (XHR `upload.onprogress`) |
| G7 | Penanda putus koneksi di jendela chat | Agent | Banner "Connection lost, reconnecting…" terhubung ke status `App.WebSocket` |
| G8 | Bahasa label panel agent | Agent | Terjemahan Bahasa Indonesia untuk string baru |
