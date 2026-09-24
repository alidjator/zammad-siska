# Inventaris Fitur Widget Customer — Baseline Zammad 7.1.3 vs HEAD

Disusun 2026-09-24 (retroaktif, atas permintaan user).

- **Baseline:** commit `a81e10e8` ("Baseline: Zammad 7.1.3 source"),
  `public/assets/chat/chat-no-jquery.coffee` (1.803 baris) + `views/*.eco`
  + `chat.scss`. Ini widget **bawaan Zammad**, sebelum perubahan SISKA apa pun.
- **Dibandingkan dengan:** `HEAD` (`chat-no-jquery.coffee` 3.935 baris).
- **Di luar cakupan dokumen ini:** fitur SISKA yang ditambahkan sesudahnya
  (Fase 5–8: form pra-chat, lampiran, tab Home/Messages/Help, pesan
  offline + OTP, KB, rating, gambar, reaksi, dst). Fitur-fitur itu dicatat
  sendiri oleh user (baseline "B", commit `85be5868`). Dokumen ini hanya
  menjawab: **fitur bawaan Zammad mana yang masih ada / berubah / hilang.**
- Hanya varian **`chat-no-jquery`** (satu-satunya yang dideploy). Varian
  jQuery dicatat di bagian 7.
- Backlog temuan masuk ke **Fase Regresi Zammad vs Tailwind** (sama dengan
  `docs/INVENTORY_AGENT_CHAT.md`).

Legenda: ✅ Tetap · 🔄 Berubah · ❌ Hilang · ⚠️ Perlu dicek/diuji

Metode: setiap opsi, callback, event WebSocket, dan method upstream
dicari pemakaiannya di `HEAD` (bukan sekadar deklarasinya), lalu jalur
kodenya dibaca. **Belum ada yang diuji di browser** (Playwright dijeda) —
kolom status berdasarkan pembacaan kode.

---

## 1. Opsi embed (kontrak dengan situs klien) — prioritas tinggi

Semua 22 opsi `defaults` upstream masih dideklarasikan di `HEAD`.

| # | Opsi (default) | Fungsi upstream | Status | Catatan |
|---|---|---|---|---|
| 1.1 | `chatId` (wajib) | Topik chat; tanpa ini widget tidak jalan ("need chatId") | ✅ | |
| 1.2 | `show` (`true`) | Tampilkan widget otomatis saat siap; `false` = hanya lewat tombol | ✅ | `onReady` → `@show()` bila `show` |
| 1.3 | `target` (`body`) | Elemen tempat widget disisipkan; objek jQuery dikonversi | ✅ | |
| 1.4 | `host` (`''`) | URL WebSocket; kosong = dideteksi dari `src` script (`detectHost`) | ✅ | |
| 1.5 | `debug` (`false`) | Log ke console | ✅ | |
| 1.6 | `flat` (`false`) | Varian tampilan datar (`.zammad-chat--flat`) | ⚠️ | Kelas & CSS masih ada, tetapi tampilannya perlu dicek di desain kit |
| 1.7 | `lang` (`undefined`) | Bahasa; kosong = `<html lang>`; `xx-YY` → `xx` | 🔄 | Lihat bagian 5 |
| 1.8 | `cssAutoload` (`true`) | Muat `chat.css` otomatis | ✅ | |
| 1.9 | `cssUrl` (`undefined`) | URL CSS kustom | ✅ | |
| 1.10 | `fontSize` (`undefined`) | Ukuran font widget | ⚠️ | Masih dipasang di `chat.eco`; ukuran komponen kit banyak memakai px tetap → efeknya perlu dicek |
| 1.11 | `buttonClass` (`open-zammad-chat`) | Tombol di situs klien yang membuka chat | ✅ | Klik → `open`, kelas inactive dilepas saat siap |
| 1.12 | `inactiveClass` (`is-inactive`) | Kelas tombol saat chat belum siap / tidak tersedia | ✅ | |
| 1.13 | `title` (`<strong>Chat</strong> with us!`) | Teks sambutan di header widget | ❌ | **Tidak dirender lagi**: nilainya masih dikirim ke `chat.eco`, tetapi template tidak memakainya. Teks sambutan kini dari phrase server (`chat_phrase_*`). Klien yang mengisi `title` tidak melihat efeknya |
| 1.14 | `scrollHint` | Teks petunjuk scroll | ✅ | |
| 1.15 | `background` (tidak ada di defaults, tapi diteruskan ke view) | Warna header/tombol | ⚠️ | Masih dipakai di 4 template; apakah menimpa warna kit perlu dicek |
| 1.16 | `idleTimeout` (6 mnt) + `…IntervallCheck` | Widget disembunyikan bila tidak dibuka | ✅ | Callback sama (`destroy(remove: true)`) |
| 1.17 | `inactiveTimeout` (8 mnt) + `…IntervallCheck` | Customer diam → layar "percakapan ditutup" | ✅ | |
| 1.18 | `waitingListTimeout` (4 mnt) + `…IntervallCheck` | Terlalu lama di antrean → layar timeout | ✅ | Salah ketik bawaan upstream `delay: @options.watingListTimeout` ikut terbawa, tetapi **tidak berdampak**: template `waiting_list_timeout.eco` tidak memakai `@delay` |

## 2. Callback untuk situs klien

| # | Callback | Status | Catatan |
|---|---|---|---|
| 2.1 | `onReady` | ✅ | |
| 2.2 | `onError(message)` | 🔄 | Upstream juga dipanggil saat **tidak ada agent online** ("No agent online") dan widget + tombol disembunyikan. `HEAD`: state `offline` masuk **mode pesan offline** (widget tetap tampil), **`onError` tidak dipanggil** untuk kasus ini. Masih dipanggil untuk `chat_disabled`, `no_seats_available`, error koneksi. Klien yang mengandalkan `onError` untuk mendeteksi "offline" akan berbeda perilakunya |
| 2.3 | `onOpenAnimationEnd` | ✅ | |
| 2.4 | `onCloseAnimationEnd` | ✅ | |
| 2.5 | `onConnectionEstablished(data)` | ✅ | |
| 2.6 | `onConnectionReestablished` | ✅ | |
| 2.7 | `onSessionClosed(data)` | ✅ | |
| 2.8 | `onCssLoaded` | ✅ | |

## 3. Ketersediaan & tombol

| # | Perilaku upstream | Status | Catatan |
|---|---|---|---|
| 3.1 | Saat render: tombol klien diberi `inactiveClass` | ✅ | |
| 3.2 | `chat_status_customer` → `online`: widget siap (menunggu CSS termuat) | ✅ | |
| 3.3 | → `offline`: widget & tombol disembunyikan | 🔄 | Diganti mode pesan offline (fitur SISKA). Lihat 2.2 |
| 3.4 | → `chat_disabled`: widget dihapus | ✅ | |
| 3.5 | → `no_seats_available`: widget dihapus + pesan jumlah antrean | ✅ | |
| 3.6 | → `reconnect`: pulihkan sesi lama | ✅ | Lihat 4.2 |
| 3.7 | `chat_error` dengan `chat_disabled` → hapus widget | ✅ | |
| 3.8 | Browser tanpa WebSocket/sessionStorage → `unsupported`, widget tidak dibuat | ✅ | |
| 3.9 | Tampilan header yang bisa diklik untuk buka/tutup (bar di pojok) | 🔄 | Diganti launcher + panel bertab (desain kit). **Struktur DOM berubah**: CSS kustom klien yang menarget `.zammad-chat-header`, `.zammad-chat-welcome`, dll bisa tidak berlaku lagi |

## 4. Siklus sesi & koneksi

| # | Perilaku upstream | Status | Catatan |
|---|---|---|---|
| 4.1 | `sessionId` disimpan di `sessionStorage` (bertahan saat pindah halaman di tab yang sama) | ✅ | + `customerName` |
| 4.2 | Reload/pindah halaman saat chat berjalan → riwayat pesan dirender ulang, widget terbuka lagi | ✅ | + sapaan & lampiran ikut dipulihkan |
| 4.3 | Pesan yang belum terkirim disimpan (`unfinished_message`) & dikembalikan | ✅ | |
| 4.4 | `beforeunload` → `chat_session_leave_temporary` | ✅ | |
| 4.5 | `hashchange` saat chat terbuka → URL baru dikirim sebagai notice ke agent | ✅ | |
| 4.6 | Posisi antrean baru ditampilkan setelah 10 dtk (`initialQueueDelay`) | ✅ | |
| 4.7 | Ping tiap 29 dtk (`ping`/`pong`) | ✅ | |
| 4.8 | Koneksi putus tak disengaja → status "Connection lost", input dinonaktifkan | 🔄 | `HEAD`: overlay "Connection lost — trying to reconnect" + **reconnect otomatis** (perbaikan SISKA) |
| 4.9 | Koneksi pulih → "Connection re-established" | ✅ | |
| 4.10 | Chat ditutup agent/customer → "Chat closed by %s", input mati | ✅ | + sapaan penutup & rating (SISKA) |
| 4.11 | Tutup widget saat sesi berjalan → sesi ditutup (`chat_session_close`) | ✅ | Kini dibedakan: saat masih menunggu → kembali ke Home tanpa rating |
| 4.12 | Layar timeout customer / antrean + tombol "Start new conversation" (`location.reload()`) | ✅ | |

## 5. Bahasa

| # | Perilaku upstream | Status | Catatan |
|---|---|---|---|
| 5.1 | Terjemahan bawaan **25 bahasa** (ca, cs, da, de, es, fa, fr, hr, hu, id, it, ko, lt, nl, pl, pt-br, ro, ru, sk, sr, sr-latn-rs, sv, tr, uk, zh-cn), 17 string masing-masing | ✅ | Blok terjemahan utuh (25 bahasa × 17 string) |
| 5.2 | Bahasa dipilih otomatis dari `lang` / `<html lang>` | 🔄 | Mekanisme masih ada, tetapi **hanya menjangkau 17 string lama**. ±26 string baru di template (`Add image`, `Attach file`, `Download`, …) dan teks dari phrase server (`chat_phrase_*`, satu bahasa, diatur admin) **tidak ikut berganti bahasa**. Widget di halaman ber-`lang="en"` / `de` tetap tampil campuran |

## 6. Penulisan pesan

| # | Perilaku upstream | Status | Catatan |
|---|---|---|---|
| 6.1 | Enter kirim, Shift+Enter baris baru | ✅ | |
| 6.2 | Ctrl/Cmd + B / I / U / S (tebal, miring, garis bawah, coret) | ✅ | |
| 6.3 | Tempel gambar (paste) → diperkecil & disisipkan inline | ✅ | Terpisah dari fitur lampiran SISKA |
| 6.4 | Seret-lepas gambar (drop) → inline di posisi kursor | ✅ | |
| 6.5 | Tempel dari Word dibersihkan (`wordFilter`) | ✅ | |
| 6.6 | Event mengetik ke agent (throttle 1,5 dtk) | ✅ | |
| 6.7 | Indikator agent mengetik (hilang setelah 3 dtk) | ✅ | |
| 6.8 | Pesan ditandai "unread" bila tab tidak aktif (`document.hidden`) | ✅ | |
| 6.9 | Pemisah waktu "Today HH:MM" tiap 2 menit | ✅ | |
| 6.10 | Petunjuk "Scroll down to see new messages" | ✅ | |
| 6.11 | Layar penuh di layar ≤ 768px + scroll halaman dikunci | ✅ | |

## 7. Varian jQuery (`chat.js` / `chat.min.js`)

| # | Temuan | Status | Catatan |
|---|---|---|---|
| 7.1 | Upstream menyediakan dua varian: jQuery & no-jQuery | 🔄 | Keputusan 2026-09-22: varian jQuery dihentikan, hanya `chat-no-jquery.min.js` yang dideploy |
| 7.2 | `https://helpdesk.satu.solutions/assets/chat/chat.min.js` **masih disajikan** (HTTP 200, 178 KB) dan **berbeda** dari build lokal (226 KB) | ⚠️ | Klien yang memasang varian jQuery mendapat widget lama yang tidak dirawat (tanpa perbaikan keamanan terbaru). **Keputusan dibutuhkan**: hapus, alihkan ke no-jQuery, atau tetap |
| 7.3 | Halaman contoh `znuny.html`, `znuny_open_by_button.html` masih memakai varian jQuery | ⚠️ | Ikut keputusan 7.2 |

---

## 8. Backlog untuk Fase Regresi Zammad vs Tailwind

| # | Item | Usulan |
|---|---|---|
| 1.13 | Opsi `title` tidak berefek | Pakai `title` bila diisi klien (menimpa phrase server), atau dokumentasikan sebagai tidak didukung |
| 2.2 / 3.3 | `onError` tidak dipanggil saat offline | Putuskan: panggil callback baru (mis. `onOffline`) atau tetap `onError` untuk kompatibilitas; dokumentasikan untuk klien |
| 5.2 | String baru tidak mengikuti bahasa halaman | Putuskan cakupan bahasa (cukup id + en?) lalu lengkapi terjemahan |
| 1.18 | Salah ketik `watingListTimeout` (bawaan upstream, tanpa dampak) | Opsional: rapikan |
| 7.2 | `chat.min.js` lama masih publik | Putuskan hapus / alihkan / biarkan |
| 3.9 | Kelas DOM lama berubah | Catat di dokumentasi embed untuk klien |
| 1.6 / 1.10 / 1.15 | `flat`, `fontSize`, `background` | Uji tampilan di fase regresi |
| — | Semua ✅ di atas | Uji di browser memakai halaman contoh `public/assets/chat/*.html` saat Playwright aktif lagi |
