# Desain: Dashboard "KPI Tim" (Item No. 8 Gap Analysis)

**Lokasi:** Tab baru di Dashboard legacy Zammad (`#dashboard`), di samping "My Stats"/"First Steps".
**Backend:** [`app/services/service/dashboard/team_kpi.rb`](../app/services/service/dashboard/team_kpi.rb) + [`app/controllers/team_kpi_controller.rb`](../app/controllers/team_kpi_controller.rb)
**Frontend:** `app/assets/javascripts/app/controllers/_dashboard/team_kpi.coffee` + `app/assets/javascripts/app/views/dashboard/team_kpi.jst.eco` (legacy CoffeeScript/jQuery, bukan Vue `/desktop` — lihat catatan arsitektur di bawah)

---

## 1. KPI yang Ditampilkan

| KPI | Perhitungan | Sifat |
|---|---|---|
| First Response Time | **Median** menit, dari `created_at` ke `first_response_at` | Rolling window (default 7 hari, bisa difilter s/d 2 tahun) |
| CSAT Score | **Average** dari `csat_score` (1-5) | Rolling window (sama seperti FRT) |
| Tiket New | Hitungan tiket dengan state type `new` | Snapshot real-time (tidak terpengaruh filter periode) |
| Tiket Open | Hitungan tiket dengan state type `open` | Snapshot real-time |
| Tiket Escalated | Hitungan tiket `escalation_at` sudah lewat & belum closed | Snapshot real-time |

## 2. Kenapa FRT Pakai Median, Bukan Mean?

Ini keputusan desain penting yang sempat diuji langsung dengan data live sebelum diputuskan.

**Masalah dengan mean (rata-rata):** distribusi waktu respons tiket itu **condong (skewed)** — mayoritas tiket dijawab cepat, tapi ada sebagian kecil yang terlantar berhari-hari sebelum akhirnya dijawab. Saat diuji dengan data staging nyata, ditemukan 3 tiket yang tidak dijawab selama **11-13 hari**, lalu ketiganya dibalas dalam rentang **5 menit yang sama** (kemungkinan besar "sapuan pembersihan backlog" oleh agent/proses tertentu). Efeknya ke **mean**: rata-rata FRT bulan itu melonjak jadi **1700-2200 menit (~28-37 jam)** — angka yang sama sekali tidak mewakili performa CS sehari-hari, padahal mayoritas tiket lain dijawab jauh lebih cepat.

**Kenapa median tidak kena masalah ini:** median cuma peduli pada "nilai di posisi tengah" kalau semua data diurutkan. Berapa pun ekstremnya 3 tiket telat itu (11 hari atau 111 hari, sama saja), posisinya tetap di ujung distribusi dan tidak menggeser median — beda dengan mean yang menjumlahkan SEMUA nilai lalu membagi rata, sehingga nilai ekstrem manapun ikut menyeret hasil akhir.

**Kenapa CSAT tetap pakai average, bukan median:** skala CSAT dibatasi 1-5 — satu skor ekstrem (misal 1) tidak bisa menyeret rata-rata sejauh outlier waktu respons yang bisa berhari-hari/tak terbatas. Untuk data dengan rentang terbatas seperti ini, average tetap representatif dan merupakan konvensi umum untuk skala kepuasan (CSAT/NPS pada umumnya dilaporkan sebagai rata-rata).

**Kesimpulan singkat:** median untuk metrik yang rentan outlier ekstrem tak terbatas (durasi/waktu), average untuk metrik dengan skala terbatas (CSAT).

*(Implementasi teknis: FRT median dihitung langsung di Postgres pakai `percentile_cont(0.5)`, bukan ditarik ke Ruby dulu — supaya tetap cepat untuk rentang sampai 2 tahun yang bisa mencakup ratusan ribu tiket. Lihat komentar di `team_kpi.rb`.)*

## 3. Rolling Window, Bukan Kalender Bulan-Berjalan

FRT & CSAT pakai **rolling window** (7/30/90/180/365/730 hari ke belakang dari sekarang), bukan "bulan berjalan". Alasannya: kalender bulan-berjalan bikin sample size tidak konsisten — di tanggal 1-3 baru ada 1-3 hari data (rawan menyesatkan), baru stabil di akhir bulan. Rolling window selalu punya jumlah hari yang sama, jadi lebih adil dibandingkan antar waktu pengecekan.

## 4. Kenapa Dibangun di Frontend Legacy, Bukan Vue `/desktop`

Dicek langsung: agent SISKA saat ini memakai frontend lama (CoffeeScript/jQuery, URL hash-routing `#dashboard`), bukan Vue baru di `/desktop` (yang halaman Dashboard-nya sendiri masih sengaja di-gate dev-only oleh tim Zammad, belum siap dipakai production). Supaya fitur ini benar-benar terlihat dan terpakai, dibangun di frontend yang aktif dipakai sekarang.

## 5. Catatan Insiden: `assets:clobber` dan Batas Styling

Saat proses styling ulang tampilan (ikon berwarna, card, dll), sempat terjadi insiden: `bundle exec rake assets:clobber` menghapus seluruh `public/assets`, termasuk file statis yang **di-commit ke git** (bukan build artifact) seperti `icons.svg` dan folder chat widget — sempat membuat seluruh frontend legacy Zammad error 500 untuk sementara sebelum dipulihkan dari source git.

Percobaan pertama memakai SCSS asli via `dartsass-rails` (mengikuti pola `zammad.scss`/`print.scss`/`knowledge_base.scss` yang sudah ada) sempat gagal dengan error `sassc` LoadError meski konfigurasinya identik dengan pola yang sudah ada. **Root cause ditemukan setelah investigasi lebih lanjut**: `assets:clobber` menghapus bukan cuma `public/assets`, tapi juga cache internal Sprockets (`tmp/cache/assets`). Begitu cache kosong total, Sprockets mencoba registrasi ulang SEMUA processor asset dari nol — termasuk `SasscProcessor` bawaannya sendiri untuk file `.scss`, yang butuh gem `sassc` untuk proses registrasi itu **meskipun tidak akan benar-benar dipakai** (karena `dartsass-rails` yang menangani kompilasi sebenarnya). Registrasi inilah yang crash saat cache kosong.

**Dikonfirmasi dengan pengujian ulang**: menjalankan `rake assets:precompile` secara manual (tanpa clobber) berhasil sempurna (exit code 0), dan restart container berikutnya dengan konfigurasi yang identik juga berhasil. Kesimpulan: **SCSS via dartsass-rails valid dan sudah dipakai untuk file ini** (`app/assets/stylesheets/team_kpi.scss`, terdaftar di `config/initializers/assets.rb` + `*= require team_kpi` di `application.css`) — cukup hindari `assets:clobber` di lingkungan ini; kalau memang perlu, harapkan precompile pertama setelahnya bisa gagal sekali dan perlu dijalankan ulang.

## 6. Redesign Visual: Mengikuti Gaya Native "My Stats"

Setelah versi awal (card rounded, ikon dibungkus lingkaran warna, 2 kartu/baris) dirasa kurang "senafas" dengan tampilan bawaan Zammad, tampilan di-desain ulang untuk meniru struktur `.stat-widget` native persis (lihat `zammad.scss`): sudut kotak (`border-radius: 1px`), ikon polos tanpa lingkaran background, help icon (`?`) menempel di dalam judul (bukan melayang di pojok card), dan grid **3 kartu per baris** (`three-columns`, sama seperti native), dengan tinggi card tetap 200px seperti native.

### 6.1 Warna: State-Based (Bukan Warna Tetap per Kategori)

Ditemukan bahwa warna hijau dominan di "My Stats" bawaan bukan warna tetap per widget, melainkan **indikator kesehatan dinamis** — tiap widget menghitung `state` (`supergood`/`good`/`ok`/`bad`/`superbad`) dari data aktual, lalu memakai class `*-color` yang sudah ada di `zammad.scss` (`fill: var(--supergood-color)`, dst). KPI Tim mengikuti pola yang sama, dengan threshold diadaptasi dari logika asli Zammad sendiri (`lib/stats/ticket_waiting_time.rb`, `lib/stats/ticket_reopen.rb`):

| KPI | Basis | supergood | good | ok | bad | superbad |
|---|---|---|---|---|---|---|
| FRT (median menit) | Cutoff absolut, diadaptasi dari `lib/stats/ticket_waiting_time.rb` (waiting time), ditambah 1 tingkat karena rolling window kita bisa jauh lebih lebar dari waktu tunggu 1 hari | ≤60 min | ≤240 min | ≤480 min | ≤1440 min | >1440 min |
| CSAT (rata-rata 1-5) | Tidak ada presedan native (tidak ada widget serupa) — skala umum industri CSAT | ≥4.5 | ≥4.0 | ≥3.0 | ≥2.0 | <2.0 |
| Escalated (% dari tiket New+Open yang lewat SLA) | Persis bucket `lib/stats/ticket_reopen.rb` (reopening rate) — rate, makin tinggi makin buruk | <20% | ≥20% | ≥40% | ≥65% | ≥90% |
| New / Open (jumlah tiket) | **Sengaja tidak diwarnai** — angka volume mentah, bukan indikator baik/buruk. Native sendiri juga membiarkan sebagian widget (mis. Channel Distribution) tanpa warna | — | — | — | — | — |

Implementasi: `team_kpi.rb` menghitung `frt_state`/`csat_state`/`escalated_state` (nilai `nil` untuk "belum ada data" atau untuk New/Open yang sengaja netral), lalu `team_kpi.coffee` mengubahnya jadi class `{state}-color` yang sama persis dipakai native — sehingga ikon (`fill`) dan angka (`color`, ditambahkan khusus karena native hanya mendefinisikan `fill` untuk class ini) otomatis serasi.

Catatan: warna baru dihitung ulang setiap kali data di-fetch (buka tab, ganti filter periode, atau reload) — tidak ada auto-refresh berkala saat ini, sama seperti "My Stats" bawaan.

### 6.2 Ukuran Ikon: Mengikuti Angka Asli Native, Bukan Seragam

Iterasi awal memakai satu ukuran seragam (40×40px) untuk semua ikon. Setelah dibandingkan dengan CSS asli native (`zammad.scss`: `.stopwatch-icon` 77×83, `.mood-icon` 60×59, `.reopening-icon` 68×47, `.in-process-icon` 64×64 — tiap ikon punya ukuran sendiri sesuai kerumitan desainnya), ukuran diubah agar tiap KPI punya box sendiri:

| KPI | Ikon | Ukuran | Acuan |
|---|---|---|---|
| FRT | `stopwatch` (dipakai ulang dari native) | 77×83 | Identik `.stopwatch-icon` native |
| CSAT | `thumbs-up` | 60×59 | Tidak ada widget native untuk CSAT — disamakan dengan `.mood-icon` sebagai analog konsep terdekat (sama-sama indikator sentimen) |
| Escalated | Custom glyph "!" (tidak ada icon di sprite untuk ini) | 60×59 | Disamakan `.mood-icon` — widget Mood native juga tentang tiket escalated |
| Tiket New | `email` | 48×48 | Tidak ada analog native — diskalakan dari proporsi asli ikon di sprite (viewBox 17×17) |
| Tiket Open | `checklist` | 52×46 | Sama seperti New, dari viewBox 16×14 |

Sempat dikira card perlu ditinggikan ke 220px supaya ikon sebesar 83px tidak sesak, tapi setelah dihitung ulang mengikuti mekanisme native (`.stat-graphic { flex: 1; display:flex; align-items:center; justify-content:center; }` menyerap sisa tinggi setelah judul/value/caption mengambil porsi tetap ~92px dari 200px), sisa ~108px sudah cukup untuk ikon 83px tanpa terpotong — sama seperti bagaimana native sendiri memuat ikon sebesar itu di card 200px tanpa penyesuaian ekstra. Card KPI Tim tetap 200px, identik native.

Ikon single-tone seperti `stopwatch` yang meng-hardcode warna path-nya sendiri (`fill="#A9BCC4"`) di-override paksa lewat CSS (`svg.team-kpi-icon path, circle, g { fill: inherit; }`) — presentation attribute SVG kalah spesifisitas dibanding selector CSS asli, jadi override ini valid dan tidak butuh `!important`.

## 7. API Endpoint (untuk Konsumsi Eksternal)

Backend dashboard ini adalah endpoint REST biasa, bisa dipanggil dari aplikasi lain di luar Zammad, tidak cuma dari tab "KPI Tim" itu sendiri.

**`GET /api/v1/team_kpi`**

| Parameter | Wajib? | Default | Catatan |
|---|---|---|---|
| `days` | Tidak | `7` | Lebar rolling window (hari) untuk FRT & CSAT. Di-clamp ke rentang 1–730 (`Service::Dashboard::TeamKpi::MAX_WINDOW_DAYS`). Tidak memengaruhi field New/Open/Escalated (selalu snapshot realtime). |

**Autentikasi**: wajib, via header `Authorization: Token token=<API_TOKEN>` (Personal Access Token dari Admin > API > Token Access, atau dibuat lewat `Token.create!(action: 'api', persistent: true, user_id:, preferences: { permission: ['ticket.agent'] })`). User pemilik token **dan** token itu sendiri harus sama-sama punya permission `ticket.agent` — kalau token dibuat tanpa `preferences: { permission: [...] }`, permission check akan selalu gagal walau user-nya sendiri punya izin (lihat `app/models/user/permissions.rb`).

**Response** (`200 OK`, `application/json`):

| Field | Tipe | Keterangan |
|---|---|---|
| `frt_median_minutes` | Float atau `null` | Median First Response Time (menit) dalam window. `null` kalau tidak ada tiket dengan `first_response_at` di window tsb. |
| `frt_state` | String atau `null` | `supergood`/`good`/`ok`/`bad`/`superbad`, `null` kalau `frt_median_minutes` juga `null`. |
| `csat_average` | Float atau `null` | Rata-rata `csat_score` (1–5) dalam window. `null` kalau belum ada rating masuk. |
| `csat_state` | String atau `null` | Sama pola dengan `frt_state`. |
| `ticket_new` | Integer | Jumlah tiket state type `new`, realtime (bukan window). |
| `ticket_open` | Integer | Jumlah tiket state type `open`, realtime. |
| `ticket_escalated` | Integer | Jumlah tiket belum closed yang `escalation_at` sudah lewat, realtime. |
| `escalation_rate_percent` | Float | `ticket_escalated / (ticket_new + ticket_open) * 100`, realtime. |
| `escalated_state` | String | Selalu terisi (`supergood`...`superbad`), tidak pernah `null`. |
| `window_days` | Integer | Nilai `days` yang benar-benar dipakai (setelah clamp). |
| `generated_at` | String (ISO8601) | Timestamp response dibuat. |

**Contoh:**
```bash
curl -H "Authorization: Token token=<API_TOKEN>" \
  "https://helpdesk.satu.solutions/api/v1/team_kpi?days=90"
```
```json
{"frt_median_minutes":558.3,"frt_state":"bad","csat_average":4.0,"csat_state":"good","ticket_new":136,"ticket_open":79,"ticket_escalated":90,"escalation_rate_percent":41.9,"escalated_state":"ok","window_days":90,"generated_at":"2026-09-16T09:15:01Z"}
```

Diverifikasi bekerja dari luar Zammad memakai akun service khusus (`integration-kpi-api@pkp.co.id`, role "Customer Services" yang punya `ticket.agent`, tidak terikat ke satu orang) — bukan akun personal siapapun, supaya integrasi tidak putus kalau pemilik akun pindah/keluar.

## 8. Auto-Refresh (Configurable)

Tab "KPI Tim" bisa refresh data sendiri secara berkala tanpa perlu reload manual, lewat Setting `team_kpi_auto_refresh_seconds` (**default 300 detik / 5 menit**, admin-editable via Admin > Settings, `0` untuk mematikan sepenuhnya). Dibuat via `script/create_team_kpi_settings.rb`.

**Kenapa polling, bukan WebSocket/push**: metrik di dashboard ini (median FRT, rata-rata CSAT, jumlah tiket) tidak butuh update sub-detik seperti live chat — kompleksitas menyambungkan ke sistem push realtime Zammad tidak sepadan manfaatnya untuk kebutuhan ini.

**Kenapa tidak boros query walau interval pendek**: timer (`setInterval`) jalan terus di background sesuai interval yang dikonfigurasi, tapi request AJAX cuma benar-benar dikirim kalau **kedua syarat ini terpenuhi**:
1. Tab browser sedang aktif/terlihat (`!document.hidden`)
2. Sub-tab "KPI Tim" di Dashboard sedang yang aktif dipilih (`!@el.hasClass('hidden')` — `Dashboard#toggle` di `dashboard.coffee` menambah/menghapus class `hidden` persis di elemen ini saat user pindah sub-tab "My Stats"/"First Steps")

Refresh otomatis ini **silent** (tidak menampilkan indikator loading, dan kalau gagal — mis. jaringan putus sesaat — tetap menampilkan data terakhir yang berhasil dimuat, bukan mengosongkan tampilan) supaya tidak mengganggu user yang sedang melihat dashboard.
