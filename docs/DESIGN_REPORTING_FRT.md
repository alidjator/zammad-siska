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

### Cakupan: Class Native yang Juga Rentan (dan Sudah Ditambahkan Guard-nya)

Setelah user menanyakan apakah batasan ini berlaku untuk semua metrik Reporting atau cuma buatan kita, seluruh class `Report::*` lain (native, bukan buatan proyek ini) yang tersedia di UI Reporting diperiksa satu per satu:

| Metrik | Class | Status |
|---|---|---|
| First Response Time (Median/Mean), CSAT | `Report::TicketFirstResponseTime`/`Mean`, `Report::TicketCsatScore` | Dilindungi (buatan proyek ini) |
| Ticket Count / Creation Channels | `Report::TicketGenericTime` | Aman — sudah punya limit bawaan sendiri (`limit = 6000`, lewat Elasticsearch) |
| Article by Type/Sender, Ticket Backlog | `Report::ArticleByTypeSender`, `Report::TicketBacklog` | Aman — `.items()` cuma `return {}`, tidak ada loop per-tiket |
| **Ticket Moved** | `Report::TicketMoved` | **Native, rentan** — sekarang **dilindungi** |
| **Ticket Merged** | `Report::TicketMerged` | **Native, rentan** — sekarang **dilindungi** |
| **First Solution Time** | `Report::TicketFirstSolution` | **Native, rentan** — sekarang **dilindungi**, dan uji langsung profile "-all-" + 1 tahun 2026 (22.977 tiket) **berhasil diblokir** oleh batas default 10.000 — bukti nyata mekanismenya bekerja |

### Bypass: Permission `report.unlimited_download`

Ditambahkan atas permintaan user: di dunia bisnis nyata, kadang ada user yang sengaja mau mengunduh data dalam jumlah besar dan menerima konsekuensi waktu proses yang lambat, tanpa mau dibatasi. Daripada menonaktifkan batasan secara global (Setting `report_download_max_records` = `0`, yang sudah didukung tapi menghapus proteksi untuk **semua** orang), dibuat **permission khusus** yang bisa di-assign selektif ke user/role tertentu.

`Report::DownloadLimitGuard.check!` menerima parameter `user:` opsional — kalau user tersebut punya permission **`report.unlimited_download`**, pengecekan batas dilewati sepenuhnya untuk request itu, berapa pun jumlah datanya. Sengaja dibuat sebagai permission **baru dan sempit**, bukan reuse dari:
- `report` (dipegang semua orang yang bisa buka Reporting sama sekali — kalau dipakai, batasan jadi nyaris tidak berarti untuk mayoritas user Reporting sehari-hari)
- `admin.system` (mengaitkan kemampuan ini ke akses pengaturan sistem yang tidak berhubungan)

**Cara assign**: Admin > Manage > Roles > pilih Role > bagian Permissions > cari "Reporting" > centang "Unlimited Report Download". Script pembuatan permission: `script/create_report_unlimited_download_permission.rb` (tidak otomatis di-assign ke Role manapun — assign manual sesuai kebutuhan).

**Diverifikasi lewat pengujian langsung** (Role & user test sementara, dihapus setelah pengujian): user tanpa permission tetap terblokir (127.001 tiket melebihi batas), user dengan permission `report.unlimited_download` berhasil melewati batas dan memproses seluruh 127.001 tiket sampai selesai (lambat karena volume asli, bukan hang tanpa akhir seperti sebelum ada guard).

`Report::TicketMoved` dan `Report::TicketMerged` memakai jalur kode `history()` (bukan query SQL langsung seperti class FRT/CSAT/FirstSolution) untuk mendapatkan `ticket_ids` — jalur ini juga **tidak punya limit sendiri**, jadi guard dipasang tepat setelah `result = history(...)` didapat, sebelum proses assets/Excel dimulai (mencakup baik jalur unduhan Excel maupun tampilan daftar JSON biasa).

**Catatan kalibrasi**: pengujian "-all- + 1 tahun penuh" pada First Solution Time menunjukkan hasil wajar bisa mencapai ~23.000 baris — di atas default 10.000. Kalau kebutuhan bisnis memang perlu unduhan sebesar itu dalam sekali klik, naikkan Setting `report_download_max_records` sesuai kebutuhan (konsekuensinya waktu proses lebih lama, ~440 baris/detik).

## 6. Indikator Loading Saat Mengambil Data Grafik

Ditemukan saat user meninjau UI Reporting: mengganti Profile/metric/tahun atau mencentang checkbox Median/Mean **tidak menampilkan indikator loading apa pun** — halaman terlihat "diam" sampai grafik tiba-tiba ter-update. Dicek langsung ke kode sumber (`app/assets/javascripts/app/controllers/report.coffee`, class `Graph`): method `render()` (yang memanggil `POST /api/reports/generate`, jalur pengambilan data grafik) memang **tidak pernah memanggil `@startLoading()`/`@stopLoading()`** — ini perilaku native Zammad, bukan sesuatu yang hilang akibat perubahan proyek ini. Indikator loading cuma ada satu kali, di pemuatan awal halaman (`GET /api/reports/config`), bukan di setiap refresh grafik berikutnya.

**Perbaikan**: `render()` diubah menerima parameter `silent` (default `false`):
- **`silent = false`** (semua pemanggilan dari aksi user — ganti Profile/metric/tahun, toggle checkbox) → menampilkan `@startLoading()`/`@stopLoading()` seperti biasa, supaya user tahu data sedang diproses.
- **`silent = true`** (dipakai khusus untuk auto-refresh berkala di background, `@delay((=> @render(true)), interval, ...)`) → **tetap diam**, tidak menampilkan indikator — supaya grafik tidak "berkedip" loading setiap beberapa menit tanpa ada aksi user (pola yang sama dipakai `team_kpi.coffee` untuk auto-refresh KPI Tim).

Diverifikasi: syntax CoffeeScript valid, precompile bersih, deploy & restart tanpa error di log.

**Bug ditemukan pasca-deploy pertama**: user melaporkan indikator loading masih belum kelihatan setelah deploy pertama. Ditemukan penyebabnya di `startLoading()` bawaan Zammad sendiri (`_application_controller/_base.coffee`):

```coffee
startLoading: (el) =>
  return if @initLoadingDone && !el   # <- di sini
  @initLoadingDone = true
  ...
```

Kalau dipanggil TANPA argumen `el`, method ini cuma benar-benar tampil **satu kali pertama** per instance controller (`@initLoadingDone` jadi `true` setelah panggilan pertama) — setiap pemanggilan berikutnya tanpa `el` langsung `return` diam-diam, tidak melakukan apa-apa. Karena constructor `Graph` sudah memanggil `@render()` sekali di awal (yang otomatis jadi "panggilan pertama" itu), semua pemanggilan `render()` berikutnya (saat user ganti Profile/tahun/checkbox) jadi tidak pernah menampilkan apa pun.

Diperbaiki dengan menargetkan elemen spesifik: `@startLoading(@$('#placeholder'))` — `#placeholder` adalah div kontainer chart yang sama dipakai `draw()` untuk plot grafik (`$('#placeholder').empty()` lalu `$.plot(...)`), jadi loading indicator muncul persis di tempat grafik biasanya tampil, dan tidak mengganggu bagian sidebar/filter di sekitarnya.

**Catatan perilaku native lain yang perlu diketahui**: `startLoading()` punya delay anti-flicker bawaan **1800ms** (`@startLoadingDelay: 1800`) — indikator baru benar-benar dirender kalau request belum selesai setelah 1.8 detik. Untuk kombinasi Profile/tahun yang responsnya cepat (di bawah 1.8 detik), user memang **tidak akan melihat spinner sama sekali** — ini perilaku bawaan Zammad untuk mencegah "kedipan" pada request cepat, bukan indikasi perbaikan tidak berfungsi.

### Tabel di Bawah Grafik — Class Terpisah, Perlu Perbaikan Sendiri

Setelah perbaikan di atas, user menanyakan kenapa **tabel daftar tiket di bawah tombol "DOWNLOAD ... RECORD(S)"** tidak ikut menampilkan loading. Ditemukan penyebabnya: tabel ini dirender oleh **class terpisah**, `Download` (bukan `Graph` yang sudah diperbaiki) — dengan AJAX-nya sendiri, `tableUpdate()`, memanggil `POST /api/reports/sets` (endpoint yang sama persis dipakai `Report::DownloadLimitGuard` di Section 5), bukan `/reports/generate`. Karena dua alur AJAX yang benar-benar independen, perbaikan di `Graph#render` sama sekali tidak menyentuh `Download#tableUpdate`.

`tableUpdate()` juga ditemukan **tidak punya `error:` callback sama sekali** — artinya kalau permintaan tabel ini kena blokir oleh `Report::DownloadLimitGuard` (mengembalikan HTTP 422), sebelumnya user tidak akan melihat pesan error apa pun untuk bagian tabel ini (beda dengan tombol Download yang sudah punya modal error terpisah).

**Perbaikan**: ditambahkan `@startLoading(@$('.js-dataDownloadTable'))` sebelum AJAX dimulai dan `@stopLoading()` di kedua callback (`success`/`error`), plus `error:` callback baru yang menampilkan `App.ControllerTechnicalErrorModal` — pola yang identik dengan `Graph#render`, termasuk daftar status code yang sama (`401, 403, 404, 422, 502`). **Tidak perlu parameter `silent`** untuk method ini (beda dengan `Graph#render`) — `tableUpdate()` cuma dipanggil dari constructor dan `selectBackend` (aksi user memilih backend/metric), sedangkan pemanggilan dari auto-refresh berkala `Graph#update` sudah punya guard sendiri (`return if @lastParams` yang tidak berubah) yang mencegah `downloadWidget.update()` terpanggil ulang selama auto-refresh diam-diam — jadi setiap pemanggilan `tableUpdate()` yang benar-benar sampai ke AJAX sudah pasti murni aksi user.

Diverifikasi: format response 422 dari server (`{error: e.message}`, lihat `handles_errors.rb#humanize_error`) cocok persis dengan yang dibaca frontend (`xhr.responseJSON.error`) — jalur error sudah tersambung end-to-end. Syntax CoffeeScript valid, precompile bersih, deploy & restart tanpa error di log.

### Bug ditemukan pasca-deploy: `startLoading()`/`stopLoading()` bisa macet

User melaporkan indikator "Loading…" **tetap tampil terus** di area grafik meskipun console browser sudah menunjukkan data asli sudah diterima dan `draw()` sudah terpanggil (`App.n(draw)` dengan objek data lengkap). Ditelusuri lebih dalam ke mekanisme `startLoading()`/`App.Delay` bawaan Zammad (`lib/app_post/delay.coffee`):

```coffee
set: (callback, timeout, key, level, queue) =>
  if key
    @clear(key, level)
  if !key
    key = Math.floor(Math.random() * 99999)   # <- key ACAK kalau tidak dikasih eksplisit
  ...
```

`startLoading(el)` sendiri memanggil `@delay(later, @constructor.startLoadingDelay)` **tanpa parameter `key` eksplisit** — jadi tiap kali dipanggil, dapat key ACAK yang berbeda. Kombinasi ini dengan timing race antara request AJAX (yang bisa selesai kapan saja) dan timer 1800ms yang menunda tampilnya "Loading…" ternyata bisa membuat indikator tetap "nyangkut" tampil walau data sebenarnya sudah datang dan `draw()` sudah jalan — kemungkinan karena `stopLoading()` cuma membatalkan TIMER-nya (`clearTimeout`), bukan mengembalikan konten yang SUDAH terlanjur di-inject kalau timer itu keburu jalan sebelum sempat dibatalkan.

**Perbaikan final**: berhenti memakai `@startLoading()`/`@stopLoading()` sama sekali untuk `Graph#render` dan `Download#tableUpdate`. Diganti dengan injeksi/pembersihan langsung yang predictable:
- Sebelum AJAX: `@$('#placeholder').html(App.view('generic/page_loading')())` (atau `.js-dataDownloadTable` untuk tabel) — muncul LANGSUNG, tanpa delay 1.8 detik (trade-off yang disengaja: lebih sering terlihat untuk request cepat, tapi dijamin tidak akan pernah macet).
- Saat sukses: `@draw()`/`tableRender()` **selalu** menimpa ulang isi elemen yang sama (`.empty()` lalu `$.plot(...)`, atau `App.ControllerTable` baru) — otomatis membersihkan apa pun yang tadi ditampilkan, tidak bergantung pada `stopLoading()` sama sekali.
- Saat gagal (`error:`): elemen dikosongkan secara eksplisit (`@$('#placeholder').empty()` / `@$('.js-dataDownloadTable').empty()`) sebelum menampilkan modal error, supaya tidak ada kondisi di mana "Loading…" tertinggal selamanya.

Pendekatan ini jauh lebih sederhana untuk dinalar dan diverifikasi dibanding mekanisme timer+key-acak bawaan, dan tidak mewarisi risiko race condition-nya.
