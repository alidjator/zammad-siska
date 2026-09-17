# Reporting First Response Time — Gap, Perbaikan, dan Median vs Mean

Bagian dari Fase 1 (Item No. 7 — Reporting Terintegrasi). Dokumen ini menjelaskan gap yang ditemukan saat review, perbaikannya, dan mengapa metrik Median dan Mean sengaja ditampilkan berdampingan (bukan salah satu saja).

## 1. Gap yang Ditemukan

Grafik native **Admin > Reporting > "First Response Time"** dengan profile **"-all-"** tampil flat di sekitar 0 menit untuk hampir semua bulan 2026.

**Dugaan awal** (bug timezone migrasi ~7 jam yang sudah dikonfirmasi sebelumnya, lihat `docs/BUG_REPORT_TIMEZONE_FIRST_RESPONSE.md`) **terbukti salah** — data September 2026 (jelas-jelas pasca-cutover migrasi, seharusnya "bersih") menunjukkan pola flat yang sama persis.

**Root cause sebenarnya**: sampel Januari-Agustus 2026 menunjukkan **~68% tiket adalah tiket *agent-initiated*** (agent membuat tiket sekaligus menulis artikel pertamanya sendiri — misal mencatat panggilan telepon yang sudah selesai ditangani), bukan tiket *customer-initiated* (customer mengirim email/chat, menunggu respons). Untuk tiket agent-initiated, `first_response_at` selalu ≈ `created_at` **by construction** (agent membuat tiket dan langsung menjawabnya dalam aksi yang sama) — ini bukan cerminan kecepatan respons yang sesungguhnya, tapi karena volumenya besar (68%), ia menenggelamkan sinyal dari tiket customer-initiated yang genuinely butuh direspons.

Dibuktikan dengan mengelompokkan berdasarkan `create_article_sender_id` (siapa pengirim artikel pertama tiket):

| Kelompok tiket | Median FRT | Keterangan |
|---|---|---|
| Artikel pertama dari **Customer** | ~25 menit | Realistis — customer benar-benar menunggu respons |
| Artikel pertama dari **Agent** | ~0.01 menit | Trivial — agent membuat + menjawab sendiri di aksi yang sama |

## 2. Perbaikan

**Report Profile baru**: `FRT: Customer-Initiated Tickets Only`
Kondisi: `ticket.create_article_sender_id = Customer`
Script: `script/create_frt_real_agent_report_profile.rb`

**Cara pakai**: Admin > Reporting > First Response Time > panel "Profiles" di kiri > pilih **"FRT: Customer-Initiated Tickets Only"** (bukan "-all-").

Hasil sesudah perbaikan (median, per bulan, Jan-Sep 2026): **26, 27, 64, 21, 50, 18, 15, 7, 7 menit** — bervariasi dan realistis, dikonfirmasi juga secara visual oleh user di browser.

## 3. Median vs Mean — Kenapa Ditampilkan Berdampingan

**Median** = nilai tengah kalau semua waktu respons tiket dalam satu bulan diurutkan dari yang tercepat ke yang paling lambat. Median hanya peduli pada *posisi* di tengah — tidak peduli seberapa ekstrem nilai-nilai di ujung atas distribusi.

**Mean** = total seluruh waktu respons dibagi jumlah tiket. Setiap nilai, sekecil atau se-ekstrem apa pun, ikut menyumbang ke total — sehingga **sangat sensitif terhadap outlier** (tiket yang direspons sangat lambat).

Kalau distribusi data **simetris**, median dan mean akan hampir sama. Tapi waktu respons tiket nyaris selalu **miring ke kanan** (right-skewed): dibatasi bawah oleh 0 menit, tapi tidak dibatasi atas — mayoritas tiket direspons cepat, tapi ada ekor panjang tiket yang terbengkalai berjam-jam bahkan berhari-hari. Untuk distribusi seperti ini, **mean akan selalu ≥ median**, dan besarnya jarak antara keduanya berubah-ubah tergantung separah apa ekor lambatnya di bulan tersebut — sesuatu yang **tidak berhubungan langsung** dengan seberapa cepat median-nya.

### Contoh Kasus Real (data live staging, Report Profile "FRT: Customer-Initiated Tickets Only")

| Bulan | Median (menit) | Mean (menit) | Rasio Mean/Median |
|---|---:|---:|---:|
| Jan | 26 | 554 | 21x |
| Feb | 27 | 685 | 25x |
| **Mar** | **64** | 729 | 11x |
| **Apr** | **21** | 475 | 23x |
| Mei | 50 | 815 | 16x |
| Jun | 18 | 698 | 39x |
| Jul | 15 | 677 | 45x |
| Agu | 7 | 740 | 106x |
| Sep* | 7 | 7 | 1x |

*\*September: sampel masih sangat kecil (bulan berjalan), belum representatif.*

**Yang perlu diperhatikan dari tabel ini**: Maret punya median **tertinggi** (64 menit — tiket "tipikal" di bulan ini memang direspons paling lambat dibanding bulan lain), tapi rasio mean-terhadap-median-nya justru **terendah** (11x) dibanding April yang median-nya jauh lebih rendah (21 menit) tapi rasionya 23x. Ini membuktikan **median dan rasio mean/median bergerak independen** — keduanya mengukur aspek yang berbeda dari sebaran data:
- **Median naik-turun** mengikuti kecepatan respons tiket yang tipikal/mayoritas.
- **Rasio mean/median** mengikuti separah apa ekor tiket-tiket outlier (yang terbengkalai) di bulan tersebut — jumlah dan tingkat keterlambatannya bisa berubah drastis dari bulan ke bulan, terlepas dari kecepatan tiket mayoritas.

Kasus paling ekstrem ada di **Agustus**: median hanya 7 menit (tim tampak responsif untuk tiket mayoritas), tapi mean 740 menit (rasio 106x) — sinyal kuat bahwa ada sejumlah kecil tiket yang benar-benar terbengkalai sangat lama di bulan itu, yang sepenuhnya tersembunyi kalau hanya melihat median saja.

### Implikasi Praktis

Menampilkan **keduanya sekaligus** memberi dua sinyal berbeda yang saling melengkapi:
- **Median tinggi** → performa tim terhadap tiket mayoritas perlu diperbaiki secara umum.
- **Mean jauh di atas median** (rasio besar) → performa mayoritas tiket sebenarnya baik-baik saja, tapi ada **segelintir tiket yang benar-benar terbengkalai** dan butuh investigasi terpisah (biasanya inilah yang paling merusak kepuasan customer, meski secara jumlah sedikit) — median saja tidak akan pernah menunjukkan gejala ini.

## 4. Implementasi Teknis

- **Backend**: `Report::TicketFirstResponseTimeMean` (`lib/report/ticket_first_response_time_mean.rb`) — query dan filter integritas data (mengecualikan tiket dengan `first_response_at < created_at`, lihat `docs/BUG_REPORT_TIMEZONE_FIRST_RESPONSE.md`) **identik** dengan `Report::TicketFirstResponseTime` (median) yang sudah ada — hanya fungsi agregasinya yang beda (mean vs median). Ini penting: memastikan kedua angka dihitung dari **populasi tiket yang persis sama**, jadi perbandingannya valid (apple-to-apple), bukan dari dua filter yang berbeda.
- **Registrasi**: backend kedua ditambahkan ke grup metrik `first_response_time` di `app/models/report.rb`; label grup diubah dari "First Response Time (median minutes)" menjadi **"First Response Time (minutes)"** karena sekarang mencakup dua statistik.
- **Cara pakai di UI**: Admin > Reporting > grup metrik "First Response Time (minutes)" > centang checkbox **Median** dan **Mean** sekaligus untuk membandingkan pada grafik yang sama.

## 5. Batasan Jumlah Unduhan (Download Limit Guard)

Saat meninjau tombol "DOWNLOAD ... RECORD(S)" di UI Reporting, ditemukan bahwa method `.items()` pada seluruh Report backend custom kita (`Report::TicketFirstResponseTime`, `Report::TicketFirstResponseTimeMean`, `Report::TicketCsatScore`) **tidak punya batas jumlah (`LIMIT`) sama sekali** — ia memproses SETIAP tiket yang cocok satu per satu (`Ticket.find` + `#assets` per tiket) untuk membangun data unduhan. Dikonfirmasi lewat pengujian langsung: kombinasi profile "-all-" + rentang multi-tahun sempat berjalan **lebih dari 1:47 menit tanpa selesai** dan harus dihentikan paksa (`kill -9`) karena membebani server — server ini juga dipakai operasional nyata tim support secara bersamaan.

**Perbaikan**: `Report::DownloadLimitGuard` (`lib/report/download_limit_guard.rb`) — modul kecil yang dipanggil di awal method `.items()` ketiga class di atas, SEBELUM loop mahal per-tiket dimulai. Ia menghitung jumlah baris yang cocok lewat query `COUNT` ringan (bukan loop penuh), lalu membandingkan dengan Setting `report_download_max_records` (default **10.000**, area `Reporting::Base`, muncul di **Admin > Settings > SISKA > Reporting**). Kalau melebihi batas, request langsung ditolak dengan pesan error yang jelas — bukan diproses sampai lambat/hang.

Nilai default 10.000 dipilih berdasarkan throughput yang diukur langsung di staging (~440 tiket/detik lewat `.items()`), supaya satu kali unduhan tetap selesai dalam ~20-25 detik bahkan di batas maksimum, sementara tetap longgar untuk kebutuhan bisnis wajar (profile nyata kita sendiri, satu tahun penuh, cuma 5.600 baris).

**Bug ditemukan saat implementasi**: percobaan pertama memakai `ticket_list.count` polos gagal dengan error SQL (`PG::UndefinedFunction: function count(bigint, timestamp, timestamp) does not exist`) — ternyata Rails ikut memakai daftar kolom dari `.select(...)` yang sudah ada di query (`tickets.id, tickets.first_response_at, tickets.created_at`) sebagai argumen `COUNT(...)`, bukan `COUNT(*)` biasa. Diperbaiki dengan `ticket_list.count(:id)` (eksplisit menghitung berdasarkan satu kolom saja). Diverifikasi lewat pengujian langsung: kondisi melebihi batas berhasil diblokir dengan pesan error yang benar, dan kondisi dalam batas tetap berjalan normal (hasil 5.600 baris identik seperti sebelum perubahan).

**Cara mengubah batas ini**: Admin > Settings > SISKA > Reporting > field "Reporting Download Max Records", atau `Setting.set('report_download_max_records', <angka>)`.
