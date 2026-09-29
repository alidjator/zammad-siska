# Desain: Dashboard "KPI Tim" (Item No. 8 Gap Analysis)

**Lokasi:** Tab baru di Dashboard legacy Zammad (`#dashboard`), di samping "My Stats"/"First Steps".
**Backend:** [`app/services/service/dashboard/team_kpi.rb`](../app/services/service/dashboard/team_kpi.rb) + [`app/controllers/team_kpi_controller.rb`](../app/controllers/team_kpi_controller.rb)
**Frontend:** `app/assets/javascripts/app/controllers/_dashboard/team_kpi.coffee` + `app/assets/javascripts/app/views/dashboard/team_kpi.jst.eco` (legacy CoffeeScript/jQuery, bukan Vue `/desktop` — lihat catatan arsitektur di bawah)

---

## 1. KPI yang Ditampilkan

| KPI | Perhitungan | Sifat |
|---|---|---|
| First Response Time | **Median** menit, dari `created_at` ke `first_response_at`, **hanya tiket yang dibuka customer** (`create_article_sender` = Customer; lihat 11.5) | Rolling window (default 7 hari, bisa difilter s/d 2 tahun) |
| CSAT Score | **Average** dari `csat_score` (1-5) | Rolling window (sama seperti FRT) |
| Tiket New | Hitungan tiket dengan state type `new` | Snapshot real-time (tidak terpengaruh filter periode) |
| Tiket Open | Hitungan tiket dengan state type `open` | Snapshot real-time |
| Tiket Escalated | Hitungan tiket `escalation_at` sudah lewat & belum closed | Snapshot real-time |

## 2. FRT: Median sebagai Angka Utama, Mean sebagai Pembanding

Ini keputusan desain penting yang sempat diuji langsung dengan data live sebelum diputuskan, dan direvisi sekali (lihat catatan revisi di bawah).

**Masalah dengan mean (rata-rata) sebagai satu-satunya angka:** distribusi waktu respons tiket itu **condong (skewed)** — mayoritas tiket dijawab cepat, tapi ada sebagian kecil yang terlantar berhari-hari sebelum akhirnya dijawab. Saat diuji dengan data staging nyata, ditemukan 3 tiket yang tidak dijawab selama **11-13 hari**, lalu ketiganya dibalas dalam rentang **5 menit yang sama** (kemungkinan besar "sapuan pembersihan backlog" oleh agent/proses tertentu). Efeknya ke **mean**: rata-rata FRT bulan itu melonjak jadi **1700-2200 menit (~28-37 jam)** — angka yang sama sekali tidak mewakili performa CS sehari-hari, padahal mayoritas tiket lain dijawab jauh lebih cepat.

**Kenapa median tidak kena masalah ini:** median cuma peduli pada "nilai di posisi tengah" kalau semua data diurutkan. Berapa pun ekstremnya 3 tiket telat itu (11 hari atau 111 hari, sama saja), posisinya tetap di ujung distribusi dan tidak menggeser median — beda dengan mean yang menjumlahkan SEMUA nilai lalu membagi rata, sehingga nilai ekstrem manapun ikut menyeret hasil akhir. Karena itu **median tetap jadi angka utama** yang mengontrol warna kartu (state) — representasi paling jujur soal "tiket tipikal".

**Revisi: Mean ditambahkan kembali sebagai angka sekunder** (bukan menggantikan median) — setelah pengalaman serupa di UI Reporting native (lihat `docs/DESIGN_REPORTING_FRT.md` Section 3) menunjukkan bahwa jarak antara mean dan median itu sendiri adalah **sinyal yang berguna**: kalau mean jauh di atas median, itu tandanya ada sejumlah kecil tiket yang benar-benar terbengkalai — persis kasus 3 tiket 11-13 hari di atas. Kartu "First Response Time" sekarang menampilkan **keduanya**: median sebagai angka besar/berwarna (tetap yang menentukan status baik/buruk), mean sebagai angka kecil di bawahnya (murni konteks, tidak diberi warna status sendiri — lihat `team_kpi.jst.eco`/`team_kpi.scss`, class `.team-kpi-value-secondary`).

**Kenapa CSAT tetap pakai average, bukan median:** skala CSAT dibatasi 1-5 — satu skor ekstrem (misal 1) tidak bisa menyeret rata-rata sejauh outlier waktu respons yang bisa berhari-hari/tak terbatas. Untuk data dengan rentang terbatas seperti ini, average tetap representatif dan merupakan konvensi umum untuk skala kepuasan (CSAT/NPS pada umumnya dilaporkan sebagai rata-rata).

**Kesimpulan singkat:** median tetap jadi ukuran utama untuk metrik yang rentan outlier ekstrem tak terbatas (durasi/waktu), tapi mean ditampilkan berdampingan sebagai indikator "seberapa parah outlier-nya" — average untuk metrik dengan skala terbatas (CSAT) tetap berdiri sendiri.

*(Implementasi teknis: FRT median dihitung langsung di Postgres pakai `percentile_cont(0.5)`, mean pakai `AVG(...)` biasa — keduanya dari populasi tiket yang persis sama (filter integritas data yang sama), bukan ditarik ke Ruby dulu, supaya tetap cepat untuk rentang sampai 2 tahun yang bisa mencakup ratusan ribu tiket. Lihat `frt_median_minutes`/`frt_mean_minutes` di `team_kpi.rb`.)*

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
| `escalated_state` | String | Selalu terisi (`supergood`...`superbad`), tidak pernah `null`. Ini breach SLA **native** (`escalation_at`). |
| `eskalasi_active` | Integer | Jumlah tiket berstatus `eskalasi` saat ini, realtime. Lihat `docs/DESIGN_ESCALATION_STATUS.md`. |
| `eskalasi_breached` | Integer | Dari `eskalasi_active`, berapa yang `escalation_deadline_at`-nya sudah lewat, realtime. |
| `eskalasi_breach_rate_percent` | Float | `eskalasi_breached / eskalasi_active * 100`, realtime. `0` kalau `eskalasi_active` nol. |
| `eskalasi_breach_state` | String | Selalu terisi (`supergood`...`superbad`). Ini breach budget **kustom** pasca-Eskalasi (`escalation_deadline_at`) — terpisah dari `escalated_state`, satu tiket bisa breach salah satu tanpa breach yang lain. |
| `window_days` | Integer | Nilai `days` yang benar-benar dipakai (setelah clamp). |
| `generated_at` | String (ISO8601) | Timestamp response dibuat. |

**Contoh:**
```bash
curl -H "Authorization: Token token=<API_TOKEN>" \
  "https://helpdesk.satu.solutions/api/v1/team_kpi?days=90"
```
```json
{"frt_median_minutes":558.3,"frt_state":"bad","csat_average":4.0,"csat_state":"good","ticket_new":136,"ticket_open":79,"ticket_escalated":90,"escalation_rate_percent":41.9,"escalated_state":"ok","eskalasi_active":1,"eskalasi_breached":0,"eskalasi_breach_rate_percent":0.0,"eskalasi_breach_state":"supergood","window_days":90,"generated_at":"2026-09-16T09:15:01Z"}
```

Diverifikasi bekerja dari luar Zammad memakai akun service khusus (`integration-kpi-api@pkp.co.id`, role "Customer Services" yang punya `ticket.agent`, tidak terikat ke satu orang) — bukan akun personal siapapun, supaya integrasi tidak putus kalau pemilik akun pindah/keluar.

## 8. Auto-Refresh (Configurable)

Tab "KPI Tim" bisa refresh data sendiri secara berkala tanpa perlu reload manual, lewat Setting `team_kpi_auto_refresh_seconds` (**default 300 detik / 5 menit**, `0` untuk mematikan sepenuhnya). Dibuat via `script/create_team_kpi_settings.rb`.

> **Cara mengubah setting ini:**
> - **Admin > Settings > SISKA > KPI Tim** — tab Admin UI baru (`app/assets/javascripts/app/controllers/_manage/siska_settings.coffee`, satu file yang sama juga menangani tab CSAT), butuh permission `admin.system`. Dibuat karena awalnya area custom `TeamKpi::Base` tidak muncul di tab manapun (layar Admin > Settings di Zammad legacy hard-coded per area bawaan) — tab ini yang mendaftarkan navigasinya, pakai mekanisme generik `App.SettingsArea` yang sama seperti tab System/Branding bawaan.
> - **Rails console/runner di server**: `Setting.get('team_kpi_auto_refresh_seconds')` untuk melihat, `Setting.set('team_kpi_auto_refresh_seconds', 600)` untuk mengubah (mis. jadi 10 menit).
> - **API**: `GET /api/v1/settings/area/TeamKpi::Base` (butuh token permission `admin.system`) untuk lihat setting ini beserta `id` numeriknya, lalu `PUT /api/v1/settings/<id>` untuk mengubah.
>
> **Bug yang sempat ada**: permission Setting ini awalnya `admin.setting_system` — nama yang tidak pernah ada sebagai Permission asli di Zammad (lihat catatan detail di `docs/DESIGN_FEEDBACK_RATING.md`). Sudah diperbaiki ke `admin.system`.

**Kenapa polling, bukan WebSocket/push**: metrik di dashboard ini (median FRT, rata-rata CSAT, jumlah tiket) tidak butuh update sub-detik seperti live chat — kompleksitas menyambungkan ke sistem push realtime Zammad tidak sepadan manfaatnya untuk kebutuhan ini.

**Kenapa tidak boros query walau interval pendek**: timer (`setInterval`) jalan terus di background sesuai interval yang dikonfigurasi, tapi request AJAX cuma benar-benar dikirim kalau **kedua syarat ini terpenuhi**:
1. Tab browser sedang aktif/terlihat (`!document.hidden`)
2. Sub-tab "KPI Tim" di Dashboard sedang yang aktif dipilih (`!@el.hasClass('hidden')` — `Dashboard#toggle` di `dashboard.coffee` menambah/menghapus class `hidden` persis di elemen ini saat user pindah sub-tab "My Stats"/"First Steps")

## 9. Semua Setting yang Configurable

Nilai-nilai kalibrasi yang sebelumnya hardcoded di `team_kpi.rb` sekarang semuanya jadi Setting — bisa diubah tanpa redeploy lewat **Admin > Settings > SISKA > KPI Tim** (permission `admin.system`), Rails console (`Setting.get`/`Setting.set`), atau API (`GET/PUT /api/v1/settings/area/TeamKpi::Base`) — lihat Section 8 untuk detail cara aksesnya.

| Setting | Default | Field | Catatan |
|---|---|---|---|
| `team_kpi_auto_refresh_seconds` | `300` | 1 field | Interval auto-refresh (detik), `0` = mati |
| `team_kpi_default_window_days` | `7` | 1 field | Default periode FRT/CSAT saat tab dibuka. `frontend: true` — dibaca juga oleh `team_kpi.coffee` lewat `App.Config`, supaya default di dropdown frontend tidak pernah beda sendiri dari backend |
| `team_kpi_max_window_days` | `730` | 1 field | Batas maksimum parameter `days` di-clamp (`Service::Dashboard::TeamKpi#initialize`) |
| `team_kpi_frt_thresholds` | `supergood_max: 60, good_max: 240, ok_max: 480, bad_max: 1440` (menit) | 4 field | Di atas `bad_max` = superbad. Makin kecil makin bagus |
| `team_kpi_csat_thresholds` | `supergood_min: 4.5, good_min: 4.0, ok_min: 3.0, bad_min: 2.0` (skala 1-5) | 4 field | Di bawah `bad_min` = superbad. Makin besar makin bagus |
| `team_kpi_escalated_thresholds` | `good_min: 20, ok_min: 40, bad_min: 65, superbad_min: 90` (%) | 4 field | Di bawah `good_min` = supergood. Makin besar makin buruk (polaritas terbalik dari FRT/CSAT). Mengukur breach SLA **native** (`escalation_at`) |
| `team_kpi_eskalasi_breach_thresholds` | `good_min: 20, ok_min: 40, bad_min: 65, superbad_min: 90` (%) | 4 field | Sama bentuk/polaritas dengan `team_kpi_escalated_thresholds`, tapi mengukur breach budget **kustom** pasca-status-Eskalasi (`escalation_deadline_at`, lihat `docs/DESIGN_ESCALATION_STATUS.md`) — sengaja dipisah karena satu tiket bisa breach salah satu tanpa breach yang lain |

Setting dengan 4 field disimpan sebagai satu hash (bukan 4 Setting terpisah) — ini format yang sama dipakai `App.SettingsAreaItem` (renderer generik Admin UI) untuk Setting multi-field, dengan key hash mengikuti `name` tiap field form.

Refresh otomatis ini **silent** (tidak menampilkan indikator loading, dan kalau gagal — mis. jaringan putus sesaat — tetap menampilkan data terakhir yang berhasil dimuat, bukan mengosongkan tampilan) supaya tidak mengganggu user yang sedang melihat dashboard.

## 10. Fase 2 BI: Scope Akses, Filter, Pembanding, dan Endpoint Baru

Latar belakang: gap analysis mockup KPI Tim sebagai dashboard BI (arah B di kanvas desain) menemukan backend hanya mengembalikan satu angka per metrik untuk satu parameter (`days`), dan **query tidak dibatasi akses grup** — setiap agent melihat angka seluruh sistem. Fase 2 menutup gap backend-nya; tampilan (`team_kpi.coffee`) belum diubah dan tetap kompatibel karena semua key respons lama dipertahankan.

### 10.1 Scope akses & filter (`Service::Dashboard::TeamKpi::Scope`)

- Semua endpoint hanya menghitung tiket di grup yang bisa dibaca user (`User#group_ids_access('read')`). **Perubahan perilaku**: angka di tab KPI Tim sekarang bisa berbeda per agent, sesuai grupnya.
- Filter opsional (array atau dipisah koma), sama di semua endpoint:

| Parameter | Isi | Kolom |
|---|---|---|
| `group_ids` | id grup | `group_id` — diiriskan dengan grup yang boleh dibaca, tidak pernah memperluas akses |
| `priority_ids` | id prioritas | `priority_id` |
| `channels` | nama tipe artikel pembuat tiket (`email`, `chat`, `web`, `phone`, `sms`, …) | `create_article_type_id` |
| `categories` | `request`, `complaint`, `information`, `no_category` | `category` |

### 10.2 Pembanding (`compare=auto|previous|yoy|none`, default `auto`)

`auto` mengikuti keputusan desain dashboard: < 1 tahun → periode sebelumnya dengan panjang sama; 1 tahun → periode sama tahun lalu (`yoy`); 2 tahun (= `team_kpi_max_window_days`) → tanpa pembanding. Metrik periode (FRT, CSAT, resolusi, reopen) dihitung ulang untuk rentang pembanding dan dikembalikan di `comparison`. Snapshot real-time (New/Open/Escalated/Eskalasi/backlog) **tidak punya pembanding** — nilai masa lalunya tidak tersimpan (butuh job snapshot berkala, belum ada).

**Batas histori 2 tahun**: production hanya menyimpan data ±2 tahun (= `team_kpi_max_window_days`). Karena itu, apa pun mode-nya, pembanding **dibuang (`null`)** kalau rentangnya mulai sebelum `sekarang − team_kpi_max_window_days` (toleransi 1 hari supaya "1 tahun vs tahun lalu" tetap tersedia saat melewati tahun kabisat) — `Scope.comparison` / `Scope.history_start`. Tanpa ini, pembanding untuk rentang panjang (mis. rentang bebas 500 hari, atau `compare=yoy` di 2 tahun) akan dihitung dari periode yang sebagian datanya tidak ada dan terlihat seperti penurunan sungguhan.

Hasilnya: < 1 tahun → periode sebelumnya; tepat 1 tahun → tahun lalu; di atas 1 tahun (termasuk 2 tahun) → tanpa pembanding.

> **Hati-hati saat menguji di staging**: staging menyimpan tiket sejak 2020-09 (±6 tahun), jadi query yang mengabaikan batas ini tetap terlihat wajar di staging tapi akan salah di production.

### 10.3 Tambahan di `GET /api/v1/team_kpi`

| Field | Keterangan |
|---|---|
| `frt_count`, `csat_count` | Ukuran sampel (n) FRT dan CSAT |
| `resolution_median_minutes`, `resolution_mean_minutes`, `resolution_count` | Waktu penyelesaian: `created_at` → `close_at` (close pertama), tiket yang closed di periode |
| `reopen_count`, `reopen_closed_count`, `reopen_rate_percent`, `reopen_state` | Versi tim dari "Reopening rate" My Stats: event `ticket:reopen` di `StatsStore` pada periode / tiket closed di periode. Bucket state sama dengan `lib/stats/ticket_reopen.rb` (20/40/65/90%) |
| `sla_by_priority` | Per prioritas: dari tiket closed di periode yang punya `close_escalation_at`, berapa closed tepat waktu. **SLA penyelesaian**, bukan respons pertama — SLA respons pertama belum dikonfigurasi di sistem ini (tidak ada tiket dengan `first_response_escalation_at`) |
| `backlog_aging` | Real-time: tiket belum closed/merged per umur (`lt_1d`, `d1_3`, `d3_7`, `d7_30`, `gte_30d`) |
| `period`, `comparison` | Rentang `{from, to}`; `comparison` = `null` atau `{mode, from, to, …metrik periode}` |
| `filters`, `group_ids_count` | Filter yang benar-benar dipakai, dan jumlah grup dalam scope |

### 10.4 Endpoint baru

| Endpoint | Isi |
|---|---|
| `GET /api/v1/team_kpi/trend?metric=frt\|csat\|volume\|resolution` | Deret waktu per `day` (≤ 30 hari) / `week` (≤ 180) / `month`, zona waktu `timezone_default`, semua bucket ada (yang kosong `value: null`). `comparison.points` sejajar per indeks. Rasio Escalated tidak tersedia sebagai tren (snapshot, lihat 10.2) |
| `GET /api/v1/team_kpi/heatmap` | 7 × 24 sel (`dow` ISO 1=Senin, `hour` 0–23): `total` tiket masuk dan `avg_per_day` (dibagi jumlah kemunculan hari itu di periode) |
| `GET /api/v1/team_kpi/agents` | Per owner: `tickets` (dibuat di periode), FRT median/mean/n (**sejak Section 21 per pembalas pertama**, plus `frt_target_met_count`/`_percent`), CSAT rata-rata/n, `escalated` & `eskalasi_breached` real-time. Owner id 1 = baris `unassigned`. **Butuh permission `team_kpi.agents` atau `admin`** (sebelumnya `report`, lihat Section 19) — menampilkan performa rekan kerja, jadi agent biasa hanya melihat angka tim |

Catatan implementasi: kolom waktu tiket bertipe `timestamptz`, jadi konversi ke waktu lokal cukup `kolom AT TIME ZONE '<tz>'` (konversi ganda `AT TIME ZONE 'UTC' AT TIME ZONE '<tz>'` menggeser 7 jam — sempat terjadi saat pengembangan, tertangkap dari heatmap yang puncaknya jatuh jam 23.00).

## 11. Fase 3 BI: Ekspor .xlsx, Data Historis 2 Tahun, Web Portal

### 11.1 Ekspor `.xlsx` — `GET /api/v1/team_kpi/export` (gap analysis No. 7)

`Service::Dashboard::TeamKpi::Export` — satu workbook, parameter sama persis dengan dashboard (`days`, filter, `compare`), jadi isi file = yang sedang dilihat. Nama file `kpi_tim_<dari>_<sampai>.xlsx` (tanggal lokal). Dibangun langsung di atas `write_xlsx` (gem yang sudah dipakai Reporting bawaan) karena `ExcelSheet` hanya menulis satu tabel per file.

| Sheet | Isi |
|---|---|
| Ringkasan | Blok konteks (periode, pembanding, filter, waktu dibuat — ada di setiap sheet), lalu tabel Metrik / Nilai / Satuan / n / Status / Pembanding / Selisih / Dasar waktu (Periode vs Real-time) |
| Tren | Per bucket: FRT median + n, CSAT + n, tiket masuk, penyelesaian median + n; tabel kedua untuk periode pembanding (kalau ada) |
| SLA per prioritas | SLA penyelesaian (`close_escalation_at`), lihat 10.3 |
| Backlog | Umur tiket belum closed (real-time) |
| Heatmap | 7 hari × 24 jam, rata-rata tiket masuk per kemunculan hari |
| Agent | **Hanya untuk permission `team_kpi.agents`/`admin`** (sama seperti `/team_kpi/agents`, Section 19); agent biasa mendapat workbook tanpa sheet ini, bukan error |

Perbaikan yang ikut: bucket tren `volume` yang kosong sekarang `0` (sebelumnya `null`, seolah "tidak ada data").

### 11.2 Data historis 2 tahun

Tidak butuh penyimpanan tambahan: semua angka dihitung langsung dari tabel `tickets` di Postgres saat diminta (tidak lewat Elasticsearch, tidak ada tabel agregat). Diukur di staging (±78 ribu tiket dalam 2 tahun), rentang 730 hari:

| Query | Waktu |
|---|---|
| Ringkasan (`/team_kpi`) | ±1,7 s |
| Tren (per metrik) | 0,1–0,4 s |
| Heatmap | ±0,2 s |
| Agent | ±2,0 s |
| Ekspor lengkap | ±2–4 s |

Index yang ada di `tickets` sudah cukup; tidak ada index baru. Batas histori pembanding: lihat 10.2.

**Catatan disk (bukan dari fitur ini)**: disk host staging terisi 94% (sisa ±8,8 GB dari 130 GB). Fitur KPI tidak menambah beban penyimpanan, tapi kalau nanti ditambah job snapshot harian (untuk tren Escalated / delta real-time) ukurannya kecil (satu baris per hari). Risiko disk tetap perlu ditangani terpisah di level server.

### 11.3 Efek scope grup pada angka (temuan saat Fase 3)

Grup **"QA - Internal Testing"** menampung 223 tiket New/Open dan 141 tiket escalated hasil pengujian. Sebelum Fase 2 tiket ini ikut terhitung di semua angka KPI. Sekarang hanya user yang punya akses ke grup QA (mis. akun uji `siska.chat.agent`) yang melihatnya; akun integrasi `integration-kpi-api@pkp.co.id` (34 dari 35 grup aktif, tanpa QA) mendapat angka operasional saja — contoh 7 hari: New 140 / Open 79 / Escalated 169, bukan 275 / 167 / 310.

### 11.4 Integrasi Web Portal (No. 8)

Keputusan: server Web Portal (Spring Boot) memanggil API ini dengan token akun integrasi; semua staf melihat angka tim yang sama. Panduan lengkap + kode referensi Spring Boot yang sudah diuji ke staging: [`INTEGRASI_WEB_PORTAL_KPI.md`](INTEGRASI_WEB_PORTAL_KPI.md), [`contrib/siska/web-portal-kpi/`](../contrib/siska/web-portal-kpi/).

Aplikasi kedua, **Laravel (PHP)**, memakai akun terpisah `integration-kpi-laravel@pkp.co.id` dengan token `ticket.agent` + `team_kpi.agents` (termasuk rekap per agent; sebelumnya `report`, Section 19): [`INTEGRASI_LARAVEL_KPI.md`](INTEGRASI_LARAVEL_KPI.md), [`contrib/siska/laravel-kpi/`](../contrib/siska/laravel-kpi/). Akun integrasi dibuat dengan `script/create_kpi_integration_account.rb` (satu akun per aplikasi, role *Customer Services*, token dibatasi ke `ticket.agent`[`,team_kpi.agents`], dengan `team_kpi.agents` akun juga diberi role *Supervisor KPI*). Untuk kebutuhan ini `/team_kpi/agents` sekarang juga mengembalikan `email` tiap agent (kunci stabil untuk dicocokkan ke tabel user aplikasi lain; `owner_id` hanya bermakna di Zammad).

### 11.5 Perbaikan definisi FRT: hanya tiket dari customer

Ditemukan saat uji live klien Spring Boot: FRT median akun integrasi **0,0 menit di semua periode** (n 65.597 untuk 2 tahun). Penyebab: ±60% tiket (39.026) **dibuat oleh agent** — email keluar, telepon yang dicatat agent — dan untuk tiket seperti itu `first_response_at` = `created_at`, jadi FRT-nya 0. Tidak ada customer yang menunggu balasan di tiket itu, jadi tidak relevan untuk FRT.

| Dibuat oleh (2 tahun, grup operasional) | Tiket | FRT median |
|---|---|---|
| Agent | 39.026 | 0,0 menit |
| Customer | 26.570 | **74,8 menit** |
| — email / sms / web / telegram / phone | 16.386 / 5.403 / 2.328 / 2.269 / 184 | 154,7 / 14,0 / 26,0 / 344,5 / 25,6 menit |

Sekarang populasi FRT ada di satu tempat, `Scope#frt_tickets` (tiket dibuat di periode, `create_article_sender` = Customer, punya `first_response_at` ≥ `created_at`), dipakai ringkasan, tren, dan agent. **Angka FRT di dashboard berubah** (contoh 90 hari: sebelumnya ±0 menit, sekarang 13,1 menit n 1.359) — angka contoh FRT 0,2 menit di mockup berasal dari bug ini.

### 11.6 Perbaikan tren: pembanding selalu sejajar

Untuk bucket minggu/bulan, rentang dengan panjang sama bisa jatuh di 14 vs 13 minggu (awal rentang di tengah minggu), sehingga titik ke-n periode ini dan pembanding tidak lagi mewakili posisi yang sama. `Trend#series(range, count:)` sekarang memaksa jumlah bucket pembanding = jumlah bucket periode ini.

## 12. Redesign Tampilan Tab KPI Tim (BI, gaya kit)

Menggantikan tampilan Section 6 (tiru `.stat-widget` My Stats). Acuan: mockup **arah B** di kanvas desain "SISKA Widget - Kit Tailwind Compliance" (artboard `TeamKpi-KitB` + `TeamKpi-KitB-States`), gaya kit Able Pro Tailwind yang sama dengan panel agent (`siska_agent_chat.scss`). File: `team_kpi.coffee` (semua hitungan tampilan), `team_kpi.jst.eco` (markup saja), `team_kpi.scss` (semua aturan dibatasi di bawah `.team-kpi`).

| Bagian | Sumber | Catatan |
|---|---|---|
| Filter bar: periode (kit `btn-group`, 7 hari–2 tahun), grup (grup yang bisa dibaca user), "Dibanding: …", waktu diperbarui, **Ekspor .xlsx** | `/team_kpi` + `/team_kpi/export` | Ekspor = navigasi ke URL ekspor dengan filter yang sama (sesi login ikut terkirim) |
| 6 kartu: FRT, CSAT, Waktu penyelesaian, Reopening rate, Rasio Escalated, Breach eskalasi | `/team_kpi` | Badge state, skala 5 tingkat dengan label ambang dari `thresholds` (Setting server, bukan angka di frontend), delta ▲▼ vs pembanding (hijau = membaik, merah = memburuk sesuai arah metrik), n sampel + peringatan "sampel kecil" kalau n < 30, mean + "Ada outlier" (mean > 3× median) di FRT. Kartu real-time: "Real-time · tanpa pembanding" |
| Antrian real-time: Total aktif, New, Open, Escalated | `/team_kpi` | Link ke overview `all_open`, `new`, `all_escalated` |
| Tren: tab FRT / CSAT / Tiket masuk / Penyelesaian | `/team_kpi/trend` | SVG: garis periode ini + putus-putus pembanding, sumbu nilai & tanggal, rata-rata dan selisih. Bucket tanpa data = garis putus (tidak ditarik ke 0). Tanpa tab Rasio Escalated (tidak ada data historis) |
| Heatmap 7 × 24 jam | `/team_kpi/heatmap` | Level relatif ke `max_avg`, tooltip = rata-rata per hari + total |
| SLA penyelesaian per prioritas | `/team_kpi` `sla_by_priority` | Label "SLA penyelesaian" (bukan respons pertama, lihat 10.3) |
| Performa per agent | `/team_kpi/agents` | **Hanya dimuat & tampil untuk `team_kpi.agents`/`admin`** (agent biasa tidak memanggil endpoint-nya sama sekali) |
| Umur backlog | `/team_kpi` `backlog_aging` | Menggantikan kartu "tiket breach" di mockup (belum ada endpoint daftar tiket breach); ≥ 7 hari diberi warna peringatan |

Kondisi data (artboard `TeamKpi-KitB-States`): skeleton saat pertama dimuat; kalau sebagian request gagal, data sebelumnya tetap tampil dengan banner "angka terakhir pukul …" + Coba lagi; kalau semua gagal dan belum ada data, kartu error; angka `null` = "—"; grafik tanpa data = pesan kosong.

Perbedaan dari mockup (keputusan saat implementasi): tanpa rentang tanggal bebas (API hanya menerima `days`), tanpa sparkline per kartu (tren sudah ada di grafik utama, menghemat 5 request per refresh), kartu "tiket breach" diganti umur backlog, target SLA per prioritas tidak digambar (belum ada Setting targetnya).

Diuji tanpa browser (Playwright ditunda): controller + template hasil compile dijalankan di Node dengan data API asli staging — 3 periode × 4 metrik × (report / agent biasa), gagal sebagian, gagal total, URL ekspor — tidak ada teks `undefined`/`NaN`, agents tidak diminta tanpa `report`, 2 tahun tanpa pembanding. **Tampilan visual belum diperiksa di browser.**

## 13. Snapshot Per Jam: Tren Rasio Escalated & Delta "vs Kemarin"

Angka real-time (New, Open, Escalated, Eskalasi aktif/breach) adalah kondisi "saat ini" — nilai masa lalunya tidak tersimpan di mana pun, jadi tanpa rekaman berkala tidak ada tren Rasio Escalated dan tidak ada pembanding untuk kartu real-time. Sekarang direkam per jam.

| Komponen | File |
|---|---|
| Tabel `team_kpi_snapshots` | `db/migrate/20260927000001_create_team_kpi_snapshots.rb`, model `TeamKpiSnapshot` (ActiveRecord biasa, bukan ApplicationModel — data statistik internal, ditulis massal) |
| Capture, pencarian, retensi | `Service::Dashboard::TeamKpi::Snapshot` |
| Job | Scheduler **"KPI Tim: snapshot per jam"** (`script/create_team_kpi_snapshot_scheduler.rb`), tiap 15 menit, aktif |

- **Isi**: satu baris per (jam, grup) untuk grup yang punya angka, plus **baris penanda** `group_id = 0` berisi total seluruh sistem — menandai jam yang sudah direkam, sehingga "jam ini semua nol" bisa dibedakan dari "tidak ada snapshot". Definisi hitungan sama persis dengan ringkasan (diverifikasi: 275 / 167 / 310 / 3 / 3 identik).
- **Sekali per jam**: job jalan tiap 15 menit tapi tidak menulis kalau penanda jam ini sudah ada (`capture(force: true)` untuk menimpa). Job terlambat/restart tetap mengisi jamnya.
- **Per grup**, supaya pembatasan akses grup (Section 10.1) tetap berlaku. **Tidak dipisah per prioritas/channel/kategori** — dengan filter itu, delta dan tren Escalated dinyatakan tidak tersedia (`reason`/`unavailable: 'filters'`), bukan dihitung salah.
- **Retensi**: dihapus kalau lebih tua dari `team_kpi_max_window_days` + 2 hari (±17 ribu baris per tahun di staging: 14 grup × 24 jam × 365 + penanda — ukuran kecil, relevan dengan catatan disk 11.2).
- **Riwayat mulai dari nol**: tidak bisa direkonstruksi ke belakang. Staging mulai 2026-09-26 22:00 UTC (27 Sep 05:00 WIB); di production mulai saat migration + script dijalankan. Tren Escalated 1 tahun baru "penuh" setahun setelahnya.
- Kolom `timestamptz` seperti kolom waktu tickets (sempat dibuat `timestamp` biasa, diperbaiki sebelum ada data — dengan `timestamp` konversi `AT TIME ZONE` di tren akan bergeser 7 jam).

API:

| Endpoint | Tambahan |
|---|---|
| `/team_kpi` | `realtime_comparison`: `{available: true, captured_at, ticket_new, ticket_open, ticket_escalated, escalation_rate_percent, eskalasi_active, eskalasi_breached, eskalasi_breach_rate_percent}` dari snapshot terdekat ke 24 jam lalu (toleransi ±2 jam), atau `{available: false, reason: filters \| no_snapshot \| no_history, history_since}` |
| `/team_kpi/trend?metric=escalated` | Per bucket: Σ escalated / Σ (new + open) × 100 atas jam-jam snapshot di bucket itu; `count` = jumlah jam snapshot; bucket tanpa snapshot = `null`. Tambahan `history_since` dan `unavailable` |
| `/team_kpi/export` | Kolom Pembanding/Selisih baris Real-time di sheet Ringkasan diisi dari snapshot kemarin; sheet Tren dapat kolom Rasio Escalated |

Tampilan tab KPI Tim: kartu Rasio Escalated dan Breach eskalasi menampilkan ▲▼ "vs kemarin, jam sama" (atau alasan kenapa belum ada), strip antrian menampilkan perubahan New/Open/Escalated vs kemarin, dan grafik tren punya tab **Rasio Escalated** (pesan "baru dikumpulkan sejak …" selama riwayat belum ada). Titik data tunggal digambar sebagai bulatan (polyline satu titik tidak terlihat). Klien Spring Boot (`KpiTrend.Metric.escalated`, `KpiSummary.realtimeComparison`) dan Laravel (`TREND_METRICS` + `escalated`) ikut diperbarui; uji unit & live keduanya lolos.

**Deploy ke production** (urutan): migration (`rails db:migrate`) → `rails runner script/create_team_kpi_snapshot_scheduler.rb` → pastikan kode ada di container/proses **scheduler** juga (job berjalan di sana, bukan di web) → restart scheduler.

## 14. Activity Stream sebagai Drawer di Tab KPI Tim

Sidebar Activity Stream bawaan (280px, selalu tampil) memakan ±¼ lebar di tab KPI Tim sehingga kartu hanya muat 3 kolom, padahal isinya (aktivitas pribadi/operasional) tidak berkaitan dengan ringkasan tim. Keputusan (mockup: artboard `TeamKpi-Activity-Closed` / `-Open`):

- **Hanya di tab KPI Tim**: sidebar disembunyikan dan diganti tombol **Aktivitas** di kanan baris tab; tombol membuka sidebar yang sama sebagai **drawer** 380px di kanan, **tanpa latar gelap** (KPI tetap bisa dibaca/dipakai). Tutup lewat tombol ✕, tombol Aktivitas, atau **Esc**. Tab My Stats / First Steps: sidebar bawaan apa adanya.
- **Diingat per user** di preferensi user (server, ikut ke perangkat lain) lewat `PUT /api/v1/users/preferences` — endpoint yang sama dengan "clues" bawaan:
  - `kpi_activity_open` (boolean) — status drawer;
  - `kpi_activity_seen_at` (ISO) — aktivitas terbaru saat drawer terakhir dibuka/ditutup.
- **Badge** di tombol: jumlah aktivitas **orang lain** yang lebih baru dari `kpi_activity_seen_at`, hanya saat drawer tertutup; user yang belum pernah membuka tidak diberi badge (bukan "25" sekaligus).

Implementasi: tetap satu `App.DashboardActivityStream` (update websocket bawaan tetap jalan), cukup opsi baru `onLoad` yang dipanggil setiap load; `dashboard.coffee` memasang `.team-kpi-host` di kontainer, `.is-kpi-tab` saat tab KPI Tim aktif, `.is-activity-open` dari preferensi; semua gaya di `team_kpi.scss` di bawah `.team-kpi-host`. Diuji dengan jsdom + jQuery asli + template hasil compile (15 skenario, termasuk badge, Esc, pindah tab, render ulang) — sempat menangkap bug `_.max` pada tanggal ISO (underscore hanya membandingkan angka → `seen_at` tersimpan `null`).

**Isi drawer (hanya tab KPI Tim)** — mockup `TeamKpi-Activity-Open`. Sidebar tab My Stats / First Steps tetap memakai daftar bawaan (`activity_stream_item.jst.eco` tidak diubah); di tab KPI Tim daftar bawaan disembunyikan (CSS) dan `dashboard/kpi_activity.jst.eco` dirender dari item `App.DashboardActivityStream` yang sama (`onLoad`, termasuk update websocket):
- **Kepala** berlatar `primary-50` (`#e2ebfe`, lebih kontras dari highlight baris baru 4%) + ilustrasi "arus aktivitas" (`team_kpi_illus` key `activity`, opasitas 45%), lalu baris "**N baru** sejak dibuka terakhir" + centang **Tampilkan otomatisasi (N)**.
- **Otomatisasi** = aktor user sistem (id 1, tampil "- updated ticket") atau tanpa nama → label "Otomatisasi" + ikon robot; **disembunyikan default**, diingat per user di preferensi `kpi_activity_show_bots`.
- **Digabung per (aktor, tiket)** selama berurutan; pesan (`Ticket::Article`) dipetakan ke tiket induknya, karena satu aksi agent biasanya menghasilkan 2 item (pesan + tiket). Kata kerja mewakili aksi paling berarti (buat tiket > eskalasi > tambah pesan > perbarui). Penghitung "N×" tidak dipakai untuk pasangan "buat tiket" (pesan + tiket baru). Dengan otomatisasi disembunyikan, aksi Admin yang tadinya diselingi otomatisasi ikut tergabung.
- **Waktu relatif** ("5 mnt lalu", "kemarin") + jam (rentang "05:56–05:57" untuk grup), diperbarui tiap menit selama drawer terbuka.
- **Baru** = lebih baru dari `kpi_activity_seen_at` saat drawer dibuka (bukan yang disimpan saat membuka — kalau tidak, sorotan langsung hilang) dan bukan aktivitas sendiri: latar tipis + titik biru. **Tandai dibaca** menghapus sorotan dan menyimpan `seen_at` terbaru.

Diuji dengan jsdom + jQuery asli + template hasil compile + data Activity Stream asli staging (20 skenario: penggabungan pesan+tiket, otomatisasi tersembunyi/tampil + preferensi, penggabungan Admin yang diselingi otomatisasi, rentang jam, waktu relatif, sorotan baru saat buka, Tandai dibaca, tutup, kosong).

## 15. Rincian di Sub-tab, ApexCharts, dan Ilustrasi Kartu

Halaman KPI Tim sebelumnya menumpuk semua bagian (±3–4 tinggi layar). Mockup: artboard `TeamKpi-Tabs` di kanvas desain.

**Tata letak** (urutan): filter bar → **Antrian real-time** → 6 kartu KPI → **kartu rincian** berisi `nav-tabs` kit (pola `admins/invoice-list.html`: di dalam card, `mr-6 py-4`, `border-b-2`, font-medium, aktif `primary-500`):

| Tab | Isi | Data |
|---|---|---|
| Tren (default) | grafik tren + ringkasan rata-rata/delta; metrik dipilih lewat `btn-group` `btn-sm` (sama dengan tombol periode, bukan deret tab ketiga) | `/team_kpi/trend` |
| Pola beban | heatmap 7 × 24 + ringkasan pola beban | `/team_kpi/heatmap` |
| SLA & Backlog | SLA penyelesaian \| Umur backlog, dua kolom di dalam kartu yang sama | dari `/team_kpi` |
| Per agent | tabel agent — tab hanya ada untuk `team_kpi.agents`/`admin` | `/team_kpi/agents` |

- **Data per tab**: `load()` mengambil `/team_kpi` + bagian tab aktif saja; tab lain diambil saat dibuka. Setiap bagian disimpan bersama kunci filternya (`partKey`: periode, grup, metrik) — data dengan filter lama tidak ditampilkan tapi diambil ulang ("Memuat…"). Auto-refresh juga hanya ringkasan + tab aktif.
- **Tab terakhir diingat per user**: preferensi `kpi_detail_tab` (`trend` / `load` / `sla` / `agents`) lewat `PUT /api/v1/users/preferences`, sama dengan drawer Aktivitas (Section 14). Nilai tidak valid, atau `agents` untuk user tanpa `team_kpi.agents`/`admin`, jatuh ke `trend`.
- **Badge di label tab** (kit `.badge` `-500/10` `rounded-full`): *SLA & Backlog* merah berisi persen SLA kalau SLA < 75%, selain itu oranye berisi jumlah tiket backlog ≥ 30 hari (kalau ada); *Per agent* berisi jumlah agent aktif dari field ringkasan **`agents_active_count`** — hanya dikirim untuk `team_kpi.agents`/`admin` (`TeamKpi.call(include_agents: agents_access?)`), dihitung dengan `DISTINCT owner_id` (tiket dibuat di periode / FRT di periode / escalated sekarang, tanpa owner 1 "Belum ditugaskan"), sama persis dengan jumlah baris tabel agent (diverifikasi 7/90/730 hari), 50–260 ms vs ±2 detik rekap lengkap. Jadi badge tampil tanpa memuat tabel agent. Tabel tetap maks. 12 baris, dengan keterangan "Menampilkan 12 agent teratas dari N".

**ApexCharts** untuk tren dan heatmap (lingkaran persen & bar tetap SVG/HTML):

- Versi **4.7.0** dari kit (`dist/assets/js/plugins/apexcharts.min.js`), lisensi **MIT** (header file); dikunci — cek ulang lisensi sebelum upgrade.
- File statis `public/assets/siska/apexcharts/apexcharts-4.7.0.min.js` (576 KB), **tidak** masuk `application.js`: dimuat lazy sekali saat grafik pertama dibutuhkan (`loadApex`, callback diantre). CSP sudah mengizinkan (`script-src 'self'`, `style-src 'unsafe-inline'`).
- Tren = gaya kit `line-chart-3` (pembanding putus-putus lewat `stroke.dashArray`, tooltip gabungan per titik, sumbu Y memakai satuan metrik, bucket tanpa data = garis putus). Heatmap = gaya kit `heatmap-chart-1` (satu warna `#4680ff`, shade otomatis, tanpa label; tooltip hari·jam, rata-rata, total). Legenda 5 kotak diganti "Makin gelap = makin ramai · maks X tiket/hari".
- Setiap render ulang (ganti tab/metrik/filter, auto-refresh) chart lama di-`destroy()` dulu; juga di `release`.

**Nilai persen gaya kit** (`team_kpi_pct.jst.eco`, pola `widget/w_statistics.html` "Total Page Views") menggantikan lingkaran progres di kartu **Reopening rate**, **Rasio Escalated**, dan total **SLA penyelesaian** (tab SLA & Backlog):
- angka besar = **jumlah tiket** (dibuka ulang / lewat SLA / closed tepat waktu);
- badge `bg-X-500/10 border border-X-500 text-X-500` = **persen**, warna mengikuti **status** (hijau Sangat baik/Baik, oranye Cukup, merah Buruk; SLA ≥ 90 / 75–90 / < 75), ikon tren tabler naik/turun = arah perubahan vs pembanding (tanpa ikon kalau belum ada pembanding, abu "—" kalau tidak ada data);
- kalimat: "Dibuka ulang dari **6.288** tiket closed. Naik **2,5 poin** vs periode sebelumnya." — angka perubahan hijau kalau membaik, merah kalau memburuk.
Persen kecil (strip antrian "63,9%", persen per prioritas SLA) tetap seperti sebelumnya.

**Ilustrasi latar** (`team_kpi_illus.jst.eco`, dekorasi `aria-hidden`): adegan duotone palet primary kit + ornamen (cincin, titik, plus, bintang, kilau, gelembung), memudar lewat `<mask>` ke arah isi, **opasitas 45%** supaya tetap latar.
- Tema: FRT jendela chat + stopwatch · CSAT rating bintang + wajah senyum · Waktu penyelesaian tumpukan tiket + jam pasir · Reopening map "Closed" → "Open" · **Rasio Escalated gauge SLA** (jarum di zona merah) · **Breach eskalasi tangga eskalasi L1–L3** dengan tiket menembus garis tenggat.
- Pojok **kanan atas** kartu (118 × 94; 80 × 64 di grid 6 kolom). Badge status dipindah sebaris dengan dasar waktu (rata kiri) dan kepala kartu menyisakan ruang kanan, supaya n sampel, skala, chip, dan baris bawah di kanan bawah tidak tertimpa.
- Strip Antrian real-time **tanpa ilustrasi** (dicoba, lalu dihapus atas keputusan review).

**Filter bar** dua baris: kontrol (Periode + Grup | Ekspor, semuanya setinggi `btn-sm` 31px) lalu keterangan kecil (Dibanding · Diperbarui) di bawah garis putus-putus — tidak terlipat tak beraturan di area sempit.

Diuji dengan jsdom + jQuery asli + template hasil compile + ApexCharts asli + data API asli (35 skenario: urutan tata letak, 2 izin × 3 periode × 4 tab, preferensi, data per tab & kunci filter, badge tab, blok persen kit termasuk data kosong, gagal per tab, loader lazy).

## 16. FRT Live Chat: Dihitung Sejak Sesi Chat Dimulai (27 Sep 2026)

Ditemukan saat user melihat tab Tren dengan akun `siska.chat.agent`: grafik FRT 7 hari **kosong** padahal ada 57 tiket yang sudah dibalas. Penyebab: tiket live chat dibuat `Chat::Session#create_ticket_for_chat!` dengan artikel pertama **System** ("Live chat dimulai."), bukan Customer, sehingga tersaring oleh definisi 11.5. Padahal tiket chat jelas dibuka customer.

Keputusan user: tiket chat **ikut FRT**, diukur **sejak customer memulai chat** (`chat_sessions.created_at`) sampai `first_response_at`. Tiket baru dibuat saat agent menerima chat, jadi `tickets.created_at` tidak mencakup waktu tunggu di antrian.

Implementasi di satu tempat, `Scope#frt_tickets`:

| Aspek | Aturan |
|---|---|
| Populasi | `create_article_sender` = Customer, **atau** `create_article_type` = chat dan punya sesi chat (`chat_sessions.ticket_id`) |
| Titik mulai (`Scope::FRT_START_SQL`) | `LEAST(COALESCE(sesi chat pertama, tickets.created_at), tickets.created_at)`. Sesi pertama = `MIN(created_at)` per tiket karena satu tiket bisa punya >1 sesi |
| Rumus menit (`Scope::FRT_MINUTES_SQL`) | Dipakai ringkasan, tren, per agent, dan ekspor (tidak ada salinan rumus lagi) |
| Filter periode & bucket tren | Tetap `tickets.created_at` |

Dampak di staging: 7 hari (akun QA) sebelumnya n 0, sekarang **median 0,5 menit, n 57**. 90 hari (seluruh sistem) n 1.342 → 1.426 (+84 tiket chat, semuanya di grup QA). Grup operasional tidak berubah selama belum ada chat produksi.

~~Catatan: tiket chat tidak punya pemilik, jadi FRT-nya muncul di baris "Belum ditugaskan".~~ Diperbaiki di 16.1.

### 16.1 Tiket chat dipegang agent penerima + distribusi AUX untuk tiket chat (28 Sep 2026)

**Pemilik tiket chat.** Keputusan user (opsi 1): tiket live chat dibuat dengan `owner` = agent yang menerima chat (`Chat::Session#user_id`), jadi FRT/KPI per agent ikut benar dan penanggung jawab tiket jelas. Pesan offline (tanpa agent) tetap tanpa pemilik, sama seperti tiket email. Saat chat dialihkan ke tiket karena agent terputus (`handover_to_ticket!`), pemiliknya dikosongkan lagi lalu langsung dibagikan AUX ke agent Available lain. Tiket chat lama (sebelum perubahan) **tidak** diisi ulang.

**Bug: trigger, notifikasi, dan AUX tidak pernah jalan untuk tiket chat.** Transaction backend Zammad (Trigger, Notification, `Transaction::AuxStatusDistribution`, dll.) hanya jalan saat `TransactionDispatcher.commit` dipanggil. Request HTTP melakukannya otomatis (`ApplicationController::HandlesTransitions`), tapi proses websocket (`Sessions::Event.run`) dan job scheduler tidak. Karena tiket chat dibuat dari websocket (kustomisasi SISKA; di Zammad asli chat tidak membuat tiket), 191 dari 198 tiket chat staging tidak pernah dibagikan AUX dan 0 tiket chat memicu notifikasi "tiket baru". Event yang tidak terkirim juga menumpuk selamanya di memori thread websocket.

Perbaikan:

| Bagian | Isi |
|---|---|
| `Chat::Session#with_ticket_transactions` | Menyisihkan buffer pemanggil, menjalankan blok, lalu `TransactionDispatcher.commit` dengan handle `application_server` (kalau belum ada), kemudian mengembalikan buffer pemanggil + sisa event. Aman dipanggil dari HTTP, websocket, maupun scheduler, termasuk bersarang |
| Dipakai di | `create_ticket_for_chat!` (live chat & pesan offline) dan `handover_to_ticket!`. **Pesan chat biasa sengaja tidak**, supaya agent tidak dapat notifikasi untuk setiap pesan customer |
| `Sessions::Event.run` | `TransactionDispatcher.reset` di `ensure`, supaya buffer websocket tidak menumpuk |

Trigger aktif yang dicek sebelum mengaktifkan: auto-reply "tiket baru" (id 1 & 54) mensyaratkan pengirim artikel Agent/Customer, sedangkan artikel pertama chat dari System, jadi **tidak** mengirim email ke customer. Trigger Help Topic (1696/1699) tidak cocok (help topic chat = Others).

Diuji di staging (rails runner, konteks tanpa handle seperti websocket, grup QA, customer `@example.invalid`, data uji dihapus sesudahnya): live chat → owner = agent penerima; pesan offline → owner kosong lalu dibagikan AUX dalam beberapa detik, notifikasi "create" ke anggota grup; pengalihan → owner pindah ke agent lain, status open, owner baru dapat notifikasi.

**Deploy:** `app/models/chat/session.rb` dan `lib/sessions/event.rb` harus ikut ke **ketiga** proses (app, websocket, scheduler). Di staging ketiga container punya salinan kode sendiri (tidak berbagi volume) dan websocket/scheduler tertinggal dari app. Perlu diselaraskan sebelum deploy production.


## 17. Anatomi Kartu KPI Seragam (28 Sep 2026)

Keputusan user setelah meninjau mockup `TeamKpi-CardAnatomy` (kanvas, baris "Sekarang" vs "Usulan"). Keenam kartu sekarang memakai satu pola. Ini menggantikan format "jumlah tiket + badge persen" gaya `w_statistics` (Section 15) yang sebelumnya dipakai Reopening dan Rasio Escalated.

| Bagian | Aturan |
|---|---|
| Kepala | Judul + ⓘ; baris kedua: chip periode/Real-time + **satu pill status berteks** (selalu di posisi ini) |
| Angka besar | **KPI itu sendiri** dalam satuan aslinya (mnt/jam, / 5, %), **selalu warna netral** (tidak ada lagi angka merah) |
| Baris perubahan | Panah + selisih + "vs pembanding"; **warna = membaik/memburuk** (bukan naik/turun). Durasi memakai "lebih cepat/lebih lambat", sama = "= sama", tanpa pembanding = "—" + catatan (abu) |
| Skala | 5 tingkat ambang dari Setting. Metrik tanpa ambang (Waktu penyelesaian): pill abu **"Belum ada target"** + jalur putus-putus "Target belum diatur" |
| Konteks | Jumlah dasar: "998 dari 32.444 tiket closed", "315 dari 445 tiket New + Open", "3 dari 3 eskalasi aktif", mean, n |

Perubahan per kartu:
- **Reopening rate:** angka besar = persen (sebelumnya jumlah tiket), jumlah pindah ke konteks.
- **Rasio Escalated:** sama, persen jadi angka besar. Konteks: tiket lewat SLA dari New + Open.
- **Breach eskalasi:** angka besar = **persen breach**, karena skala ambangnya persen (`team_kpi_eskalasi_breach_thresholds`). Delta vs kemarin dalam poin. Konteks: jumlah lewat batas dari eskalasi aktif.
- **Waktu penyelesaian:** mendapat pill "Belum ada target" (atau "Tidak ada data" kalau kosong).

Tidak berubah: blok SLA di tab SLA & Backlog masih memakai `team_kpi_pct.jst.eco`, dan peringatan "sampel kecil" tetap hanya untuk kartu periode (bukan real-time). Test: `tabs_test.js` skenario "anatomi: …" (menggantikan dua skenario "persen: …").

## 18. Quick Win BI: Filter, Pembanding, Cakupan CSAT, Drill-down (28 Sep 2026)

Paket pertama dari analisa gap BI (quick win #1, #2, #7, #10), sesuai mockup `TeamKpi-QuickWin` dan `TeamKpi-QuickWin-States` yang **mengikuti komponen kit Able Pro Tailwind v1.2.0** (`src/assets/scss/partial/{choices,forms,buttons,modal,table}.css`).

**Filter bar**
- Baris 1: Periode (btn-group) + Ekspor.
- Baris 2 (`form-label` di atas kolom, grid 5 kolom, 3/1 kolom di area sempit):
  - Grup dan **Pembanding** (`form-select`).
  - **Prioritas**, **Kanal**, **Kategori** (**Choices.js 11.1.0** dari kit, `public/assets/siska/choices/`, dimuat lazy seperti ApexCharts). Pilihan aktif tampil sebagai chip di dalam kolom. Jumlah tiket per opsi tampil lewat `data-label-description`, hanya di daftar pilihan.
- Baris 3: "Dibanding: …", "Diperbarui", dan **Reset filter** (`btn-link-secondary`, hanya muncul kalau ada filter aktif).
- Pembanding memakai param API `compare` yang sudah ada: `auto` / `previous` / `yoy` / `none`.
- Filter tidak disimpan ke preferensi, hanya selama tab dibuka. Karena tab dirender ulang tiap memuat data, Choices.js dipasang ulang setelah setiap render.
- `GET /api/v1/team_kpi/filter_options` (`TeamKpi::FilterOptions`): jumlah tiket dibuat di periode, **hanya dengan filter grup** (dimensi lain diabaikan supaya daftar tidak menyusut saat memilih). Kanal dasar (email/web/phone/sms/chat) selalu ada walau 0. Kalau endpoint gagal, daftar tetap bisa dipakai tanpa jumlah, tanpa banner gagal.

**Cakupan rating CSAT**
- Rumus: rating masuk / tiket closed di periode (`csat_count / reopen_closed_count`).
- Ditandai "belum representatif" (warning) kalau < `CSAT_COVERAGE_MIN` (5%) atau n < 30.
- Ini bukan "tingkat respons survei": rating dari widget tidak mengisi `csat_email_sent_at`, jadi survei terkirim belum bisa dihitung.

**Drill-down**
- Tautan "Lihat … tiket →" di baris konteks tiap kartu, disembunyikan kalau jumlahnya 0.
- Membuka `App.DashboardTeamKpiDrill` (turunan `App.ControllerModal`, gaya kit `modal-lg` 800 px) berisi `table-hover` 50 tiket teratas: Tiket, Judul, Grup, Agent, tanggal metrik, dan nilai (FRT/Skor/Penyelesaian).
- Footer: **Ekspor daftar** (CSV sampai 5.000 baris, BOM UTF-8) dan **Buka di pencarian** (nomor 50 tiket yang tampil, lewat pencarian Zammad).
- `GET /api/v1/team_kpi/tickets?metric=frt|csat|resolution|reopen|escalated|breach[&format=csv]` (`TeamKpi::Tickets`). **Populasinya sama persis dengan kartunya**, diuji dengan data staging: frt 8.361, resolution 32.441, reopen 998, escalated 169, dan breach 2, semuanya = angka kartu. Filter kanal Chat: 86 = 86.

| Metrik | Urutan | Kolom tanggal |
|---|---|---|
| frt | terlama direspons | Dibuat |
| csat | terbaru | Dinilai |
| resolution | terlama selesai | Closed |
| reopen | terbaru dibuka ulang (StatsStore `ticket:reopen`) | Dibuka ulang |
| escalated (real-time) | paling lama lewat SLA | Lewat SLA sejak |
| breach (real-time) | paling lama lewat batas | Batas eskalasi |

Test: `tabs_test.js` 41 skenario (6 baru "quick win: …", termasuk Choices.js asli di jsdom). Catatan data staging: semua tiket berprioritas "2 normal", jadi filter Prioritas belum teruji dengan data yang bervariasi.

**Kepala Periode** (artboard `TeamKpi-FilterHead` opsi A → `TeamKpi-PeriodRadio` opsi B → `TeamKpi-HeadSplit` opsi A)
- Kepala Periode **berdiri sendiri** sebagai kartu `primary-50` (bingkai primary-100), berjarak 12 px dari kartu filter putih di bawahnya (artboard `TeamKpi-HeadSplit` opsi A; `.team-kpi-bar` hanya pembungkus). Isinya: ikon kalender, judul "Periode" + rentang tanggal, pilihan periode, dan tombol **Ekspor .xlsx**.
- Pilihan periode = **radio dalam kotak** (pola *mega option* kit, `forms/form2_megaoption.html`): `<input type="radio" name="kpi-period">` di dalam `label.team-kpi-period-opt`, bingkai primary untuk yang terpilih, radio gaya kit `form-check-input`. Grup `role="radiogroup"`.
- Event `change .js-kpi-period` → `onPeriod` membaca `value`. Karena tab dirender ulang tiap memuat, radio terpilih difokuskan lagi kalau fokus ada di grup radio (panah kiri/kanan tetap jalan).
- Ornamen jadi pengisi fleksibel di antara grup Periode dan Ekspor: hanya tampil di ruang yang benar-benar sisa, rata kanan dekat Ekspor, dan disembunyikan saat lebar kontainer ≤ 1160 px (satu baris pita butuh ±1000 px). Label radio membatalkan gaya global `label` Zammad (uppercase + letter-spacing); kalau pita membungkus, Ekspor tetap rata kanan.

## 19. Permission `team_kpi.agents`: Siapa Boleh Melihat Angka Agent Lain (29 Sep 2026)

**Latar belakang.** Sampai 28 Sep, angka agent lain (tab *Per agent*, badge jumlah agent, sheet *Agent* di ekspor .xlsx, `GET /team_kpi/agents`) dibuka untuk permission `report` atau `admin`. Data staging 29 Sep:

| Pemegang `report` | Keterangan |
|---|---|
| Admin (3 user) | wajar |
| **Customer Services** (10 user aktif) | seluruh role, bukan hanya supervisor: 5 orang, `agent@`, 2 akun integrasi, 2 akun uji `siska.chat.agent`/`agent2` |
| Client - Koordinator (151 user) | **customer**, `report` + `ticket.customer`. Tidak bisa masuk KPI karena semua endpoint mewajibkan `ticket.agent` dulu (`require_agent`), jangan dilonggarkan |

Jadi setiap agent Customer Services bisa melihat performa semua rekannya. Ini dianggap tidak disengaja.

**Kenapa bukan sub-permission `report.*`.** Zammad memberi semua anak dari permission yang dipegang (`Auth::Permissions` memeriksa `Permission.with_parents`). Diuji di staging: user yang hanya punya `report` lolos `permissions?('report.unlimited_download')`, bahkan `permissions?('report.xyz_tidak_ada')`. Efek samping: batas unduhan Reporting (`report.unlimited_download`, `lib/report/download_limit_guard.rb`) saat ini tidak membatasi pemegang `report` mana pun. Ini dicatat sebagai tugas terpisah.

**Definisi** (pola bawaan Zammad `chat` / `knowledge_base`), dibuat oleh `script/create_team_kpi_agents_permission.rb`:

| Permission | Label | Keterangan |
|---|---|---|
| `team_kpi` | KPI Tim | induk, `disabled: true` (tidak bisa dicentang), prio 1542 |
| `team_kpi.agents` | Lihat KPI per agent | melihat angka agent lain, prio 1543 |

Script yang sama membuat role tambahan **Supervisor KPI** (hanya `team_kpi.agents`, tanpa akses grup), yang ditambahkan di atas role kerja user. Script tidak memberikan role ke siapa pun.

**Aturan akses.**
- `TeamKpiController#agents_access?` = `permissions?(%w[team_kpi.agents admin])`, dipakai di `/agents` (403), `include_agents` ringkasan (`agents_active_count`), dan ekspor (sheet Agent). Frontend: `@canSeeAgents` di `team_kpi.coffee` memeriksa hal yang sama.
- Supervisor tetap hanya melihat tiket, dan karena itu hanya agent, di grup yang bisa ia baca (`Scope`).
- `ticket.agent` tetap wajib untuk semua endpoint.
- **Token API:** Zammad mensyaratkan user **dan** token sama-sama punya izin. `script/create_kpi_integration_account.rb` sekarang menerima `ticket.agent[,team_kpi.agents]` (bukan `report`) dan, dengan `team_kpi.agents`, memberi akun itu role Supervisor KPI.

**Transisi** (akses yang ada dipertahankan sementara, sampai tim memberi daftar supervisor):

| Akun | Supervisor KPI | Alasan |
|---|---|---|
| 5 orang Customer Services (id 50, 1111, 2934, 30393, 36039) dan `agent@pkp.co.id` | ya, sementara | sebelumnya bisa melihat; dikurangi setelah daftar supervisor dari tim |
| `integration-kpi-laravel@` | ya | rekap per agent di aplikasi Laravel; **token production perlu dibuat ulang** dengan `ticket.agent,team_kpi.agents` |
| `siska.chat.supervisor@` (id 77577, dulu `siska.chat.agent2@`) | ya | akun uji kasus supervisor |
| `siska.chat.agent@` (id 77503) | tidak | akun uji kasus agent biasa |
| `integration-kpi-api@` | tidak | tokennya hanya `ticket.agent`, tidak pernah memakai data per agent |

**Status staging (29 Sep):** role Supervisor KPI sudah dipasang ke 8 akun di atas, dengan izin user. Hasil cek: ke-8 akun dan admin lolos `agents_access?`; `siska.chat.agent` dan `integration-kpi-api` tidak. Supaya nama akun uji sesuai perannya, `siska.chat.agent2@` diganti nama menjadi `siska.chat.supervisor@pkp.co.id` ("SISKA Chat Supervisor") dan diberi role Supervisor KPI; `siska.chat.agent@` ("SISKA Chat Agent") dilepas dari role itu dan jadi agent biasa.

Setelah dipasang, agent Customer Services tanpa role Supervisor KPI tidak lagi melihat tab Per agent. Sebaiknya diumumkan dulu.

**Deploy production:** jalankan `script/create_team_kpi_agents_permission.rb`, beri role Supervisor KPI ke daftar supervisor, lalu buat ulang token Laravel.

**Pengujian.** `tabs_test.js` 44 skenario. Skenario "akses per agent (Section 19)" memakai stub `permissionCheck` yang meniru pewarisan induk Zammad: `team_kpi.agents` dan `admin` melihat tab Per agent; `report` dan `report` + `report.unlimited_download` tidak; agent biasa tidak.

## 20. Target FRT per Grup atau per Kanal (29 Sep 2026)

**Latar belakang.** Ambang FRT sebelumnya satu untuk semua tiket (`team_kpi_frt_thresholds`: Sangat baik ≤ 60, Baik ≤ 240, Cukup ≤ 480, Buruk ≤ 1440 menit). Data staging 90 hari menunjukkan FRT median per grup sangat berbeda: Customer Services 0,1 jam, CS_gajianduluan.id 6,1 jam, Business Support 4,9 jam, Corporate Legal 46,3 jam, Operational Quality Excellence 56,4 jam. Per kanal perbedaannya kecil (0–0,4 jam). Satu target membuat agent grup spesialis selalu merah, padahal SLA penyelesaiannya 100% (mockup `TeamKpi-Agent`).

**Keputusan user.**
- Target bisa diatur: per grup (default) atau per kanal.
- Per grup/kanal diisi satu angka (batas "Baik").
- Kalau tampilan mencakup banyak grup, status = **% tiket sesuai target**: tiap tiket dinilai dengan target grup/kanalnya sendiri.

**Tempat mengatur** (dibuat `script/create_team_kpi_frt_target.rb`):

| Isian | Tempat | Keterangan |
|---|---|---|
| `Group.frt_target_minutes` "Target FRT (menit)" | Admin › Groups › edit grup | atribut ObjectManager (integer, boleh kosong). Kosong = target global |
| `team_kpi_frt_target_basis` "Dasar target FRT" | Admin › SISKA › KPI Tim | `group` (default) / `channel` |
| `team_kpi_frt_target_by_channel` "Target FRT per kanal (menit)" | Admin › SISKA › KPI Tim | Email, Web, Phone, Chat, SMS, Telegram, WhatsApp. Kosong = target global |
| ~~`team_kpi_frt_target_met_thresholds`~~ | — | **dihapus 29 Sep** (Section 22.4): status mengikuti `team_kpi_escalated_thresholds` atas % tiket terlambat |

**Target global** = `good_max` di `team_kpi_frt_thresholds` (240 menit).

**Perhitungan** (`Scope.frt_target_sql` + `FRT_TARGET_JOIN`, di `TeamKpi#frt`): populasi sama dengan FRT (`Scope#frt_tickets`: tiket dibuat customer, live chat sejak sesi dimulai). Target per tiket = `COALESCE(NULLIF(groups.frt_target_minutes, 0), global)`, atau `CASE ticket_article_types.name … END` untuk dasar per kanal. Dihitung `COUNT(*) FILTER (WHERE frt <= target)`, serta MIN/MAX target.

**Field API baru** di ringkasan dan `comparison` (field lama tidak berubah):

| Field | Isi |
|---|---|
| `frt_target_met_count`, `frt_target_met_percent` | jumlah dan % tiket dengan FRT ≤ targetnya |
| `frt_target_minutes` | target (menit) kalau satu target berlaku untuk seluruh populasi (mis. filter satu grup); `null` kalau campuran |
| `frt_target_basis` | `group` / `channel` |
| `frt_target_state` | status dari % sesuai target (supergood … superbad), `null` kalau Setting ambang belum ada |
| `thresholds.frt_target_met` | ambang % yang dipakai |

**Diuji di staging** (180 hari, admin; target Legal diuji dalam transaksi yang di-rollback):

| Skenario | % sesuai target | Target | Status |
|---|---|---|---|
| belum ada target grup (semua 240 menit) | 68,1% (2.299 / 3.377, cocok dengan hitungan independen) | 240 | Buruk |
| Legal = 48 jam, semua grup | 73,4% | campuran (`null`) | Cukup |
| filter Legal saja | 67,8% | 2.880 | Buruk |
| filter Customer Services saja | 80,9% | 240 | Baik |
| per kanal (email 60, web 480) | 61,2% | campuran | Buruk |
| per kanal, filter email | 56,7% | 60 | Buruk |

**Perhatian untuk tampilan (belum diubah):** kartu FRT sekarang masih berstatus dari median vs ambang global. 180 hari: median 19,7 menit = "Sangat baik". Dengan status baru, angka yang sama menjadi **68% sesuai target = "Buruk"**, karena 32% tiket menunggu lebih dari 4 jam. Ini perubahan makna yang terlihat. Ambang % (90/80/70/50) dan target tiap grup perlu dikalibrasi bersama tim sebelum tampilan diganti. Tampilan kartu menunggu mockup disetujui.

**Tampilan (user memilih B2, mockup `TeamKpi-FrtTarget`):**
- Kartu **"FRT sesuai target"**: angka besar = % tiket sesuai target. Pill dan skala 5 tingkat dari `frt_target_state` / `thresholds.frt_target_met`. Baris perubahan dalam poin (naik = membaik).
- Baris konteks (`team-kpi-context`): "Median X · target Y" (target tunggal, mis. filter satu grup) atau "target per grup" / "target per kanal".
- Kaki kartu: "Sesuai target: N dari M tiket".
- Tab Per agent: kolom **"FRT sesuai target"** (%, warna dari ambang yang sama). Tooltip berisi median dan jumlah tiket (pembalas pertama).
- Ekspor .xlsx: baris "FRT sesuai target" di Ringkasan (median tanpa status) dan kolom "FRT sesuai target (%)" di sheet Agent.
- Tren tetap "FRT median".

## 21. Atribusi Metrik per Agent: FRT ke Pembalas Pertama (29 Sep 2026)

**Keputusan user:** "yang achieve atas FRT yang membalas pertama kali, adapun achieve penanganan berhak kepada yang terakhir on hand."

| Metrik | Milik | Implementasi |
|---|---|---|
| FRT (median, n, % sesuai target) | **agent yang pertama membalas** = penulis artikel Agent publik pertama | `Scope::FRT_RESPONDER_JOIN` (LEFT JOIN LATERAL, kolom `frt_resp.responder_id`) |
| Waktu penyelesaian, SLA penyelesaian, dibuka ulang, CSAT | **pemilik terakhir** (owner saat closed) | `tickets.owner_id`; dibuka ulang = `StatsStore ticket:reopen` per user |
| Antrian real-time (aktif, escalated, breach) | **pemilik sekarang** | `tickets.owner_id` |

**Kenapa perlu.** Data staging 90 hari s.d. 22 Agu: 67% tiket dibalas pertama oleh orang lain, bukan pemilik akhirnya. Sebelum perubahan, tab Per agent menampilkan FRT agent 70688 **30,1 jam (n 256, per owner)**, sedangkan mockup KPI Saya menampilkan **33,4 jam (n 243, per pembalas)**. Dua angka berbeda untuk orang yang sama. Di live chat, owner sering dikosongkan lagi setelah agent terputus (Section 16): dari 86 tiket chat 60 hari hanya 2 yang pemiliknya = pembalas pertama. Per owner, FRT chat jatuh ke baris "Belum ditugaskan".

**Definisi bersama** untuk kartu tim, tab Per agent, dan KPI Saya (nanti):
- **Populasi:** selalu `Scope#frt_tickets`, yaitu tiket dari customer, plus live chat yang dihitung sejak sesi dimulai. KPI Saya tidak memakai query sendiri: query mockup `scripts/agent_data.rb` melewatkan tiket chat (artikel pertamanya System).
- **Menit:** `FRT_MINUTES_SQL` (`first_response_at` − awal). `first_response_at` cocok dengan artikel Agent publik pertama di 2.122 dari 2.125 tiket (selisih > 1 menit: 3).
- **Target:** per tiket (Section 20).

**Perubahan.**
- `Agents#frt_by_responder` menggantikan `frt_by_owner`. Setiap baris agent menambah `frt_target_met_count` dan `frt_target_met_percent`.
- `agents_active_count` memakai pembalas pertama untuk bagian FRT.
- Sheet *Agent* di ekspor .xlsx dan klien Laravel (`/team_kpi/agents`) ikut berubah otomatis.

**Diuji di staging** (180 hari):

| Akun | Kartu tim: FRT n / sesuai target | Jumlah seluruh baris agent | Badge jumlah agent = jumlah baris |
|---|---|---|---|
| admin | 3.376 / 2.298 | 3.376 / 2.298 | 79 = 79 |
| supervisor (dengan grup QA) | 3.463 / 2.385 | 3.463 / 2.385 | 82 = 82 |

Baris "Belum ditugaskan" tidak punya FRT lagi (n 0). Agent 70688: median 1.314 menit, n 460, 28,7% sesuai target, cocok dengan hitungan independen.

**Belum:** tampilan tab Per agent dan kartu FRT belum menampilkan % sesuai target (menunggu keputusan B1/B2, Section 20). Keterangan tabel Per agent perlu menyebut "FRT = pembalas pertama".

## 22. Dasar Waktu FRT: Jam Kerja (default) atau Jam Kalender (29 Sep 2026)

**Keputusan user:** opsi C, yaitu bisa diatur di Setting dengan default jam kerja. Saat ini belum ada grup yang bekerja di luar jam kantor, tapi ke depannya akan ada.

**Sumber jam kerja.** `tickets.first_response_in_min`, dihitung Zammad sendiri dengan **kalender SLA tiket**. Saat ini kalender "Indonesia/Jakarta" (Sen–Jum 08.00–17.00, 52 hari libur) dipakai oleh ke-57 SLA. Kolom ini terisi untuk 97% populasi FRT (1.505 dari 1.551 tiket, 90 hari). **Grup yang nanti bekerja di luar jam kantor:** cukup buatkan SLA untuk grup itu dengan kalender 24/7 (atau shift-nya) di Admin › Calendars / SLAs. FRT jam kerja grup itu otomatis mengikuti, tanpa perubahan kode.

**Rumus** (`Scope.frt_minutes_sql`, dipakai di kartu, tren, tab Per agent, drill-down, dan ekspor):

| Setting `team_kpi_frt_time_basis` | Menit FRT |
|---|---|
| `business` (default) | `first_response_in_min`; **kecuali** live chat (tetap sejak chat dimulai, karena antrian chat dihitung) dan tiket tanpa `first_response_in_min` (tidak cocok SLA mana pun) → jam kalender |
| `calendar` | `FRT_MINUTES_SQL` (24×7, seperti sebelumnya) |

Target FRT grup/kanal (Section 20) dibaca dalam dasar waktu yang sama. Ringkasan menambah `frt_time_basis` dan `frt_calendar_median_minutes` (median jam kalender sebagai konteks pengalaman customer). `/team_kpi/tickets?metric=frt` menambah `frt_time_basis`.

**Tampilan:**
- Baris konteks kartu: "Median 7 mnt kerja · target per grup · kalender 19,3 mnt".
- Tooltip tab Per agent: "Median … kerja".
- Kolom drill-down: "FRT (jam kerja)".

**Diuji di staging** (180 hari, admin, target global 4 jam):

| Dasar waktu | Median | % sesuai target | Jumlah baris agent = tim |
|---|---|---|---|
| jam kerja | 7,0 mnt (kalender 19,3) | 87,0% | 3.358 / 2.922 = 3.358 / 2.922 |
| jam kalender | 19,3 mnt | 68,0% | 3.358 / 2.283 = 3.358 / 2.283 |

Contoh: tiket masuk Jumat malam dan dibalas Senin tercatat 73,4 jam kalender = 540 menit (9 jam) kerja.

**Catatan data:** 8 tiket Operational Quality Excellence (90 hari) tidak punya `first_response_in_min`, jadi tidak cocok SLA mana pun, dan tetap dihitung jam kalender. SLA grup ini perlu dicek.

**Target live chat** (Setting `team_kpi_frt_target_chat_minutes`, default **4 menit** = `waitingListTimeout` widget chat (Section 22.4); awalnya 2, boleh desimal). Menit jam biasa sejak customer memulai chat. Selalu dipakai untuk tiket chat (`frt_chat`, sama dengan pengecualian menit), apa pun dasar target grup/kanal. Kosong/0 = chat ikut target grup/kanal. Alasannya: chat hanya terjadi saat agent online dan customer menunggu langsung di layar. Tanpa target sendiri, target grup (mis. CS 15 menit kerja) membuat hampir semua chat otomatis "sesuai".

Staging, grup QA, 90 hari, 86 chat: median 23 detik, p90 1,5 menit, maks 20,5 menit.

| Target chat | % sesuai |
|---|---|
| 2 menit | 91,9% (79/86) |
| kosong → target grup 4 jam | 100% |

Per agent (pembalas pertama): SISKA Chat Agent 57/60, Agent 03 21/25. Angka tim tanpa chat tidak berubah (87,0%).

Pesan offline widget (kanal *web*) tetap tiket biasa: menit kerja + target grup.

### 22.1 Target per grup yang disepakati (sejak 22.5 hanya dipakai kalau Dasar target FRT = Per grup)

Dibahas satu per satu dari usulan berbasis data 90 hari, jam kerja. Prinsip: target di titik yang sekarang sudah dicapai ±75–85% tiket.

| Grup | Target | Status | Keterangan |
|---|---|---|---|
| Customer Services | **15 menit kerja** | disepakati 29 Sep, terpasang di staging | median 4 mnt kerja; 180 hari: 87,6% sesuai (Baik). Dari 3 agent pembalas utama, yang terlemah 77,7%. Chat CS memakai target chat (2 mnt). Dievaluasi ulang setelah 1 bulan data production, belum dikaitkan ke penilaian kinerja |
| CS_gajianduluan.id | **1 hari kerja (540)** | dari data (22.4), terpasang di staging | 180 hari: 88,9% |
| Corporate Legal & IR | **2 hari kerja (1080)** | dari data (22.4), terpasang di staging | 180 hari: 87,9% |
| Business Support | **2 hari kerja (1080)** | dari data (22.4), terpasang di staging | 180 hari: 74,1% |
| grup < 30 tiket / 90 hari | kosong (global 4 jam kerja) | 22.2 | — |

Efek sementara (180 hari, admin): kartu tim **87,0% → 78,9% (Cukup)**, karena CS sekarang lebih ketat sementara grup lain masih memakai target global 4 jam kerja.

**Deploy production:** isi target yang sama di Admin › Groups.

### 22.2 Grup kecil dan sampel kecil (keputusan 29 Sep; tampilan dikoreksi di 22.5)

**Target grup kecil: opsi B.** Grup dengan kurang dari 30 tiket FRT per 90 hari **dikosongkan**, jadi memakai target global 4 jam kerja. Target tidak ditarik dari data 1–20 tiket, karena satu tiket menggeser angka 5–13 poin. Yang terkena (staging, 90 hari):

| Grup | Tiket |
|---|---|
| Contract & Database | 20 |
| Payroll & Absence | 19 |
| Contract Benefit | 16 |
| Marketing | 13 |
| Operational Quality Excellence | 8 |
| 5 grup lain | ≤ 3 |

**Tampilan di bawah 30 data: opsi (ii), status disembunyikan** (`SMALL_SAMPLE` = 30).
- **Kartu periode** (FRT, CSAT, Reopening): pill **"Sampel kecil"** (oranye) menggantikan status, tanpa skala 5 tingkat. Catatan di kartu: "Hanya N tiket, angka mudah berubah. Status tidak ditampilkan di bawah 30." Angkanya tetap tampil. Kartu real-time tidak terkena.
- **Tab Per agent:** sel "FRT sesuai target" dan "CSAT" tanpa warna kalau n < 30. Tooltip menambah "sampel kecil, tanpa status".
- **Ekspor .xlsx:** kolom status di Ringkasan berisi "Sampel kecil".
- **API tidak berubah:** `*_state` tetap dikirim, supaya klien lain bisa memutuskan sendiri.

### 22.3 Tindak lanjut saat production (WAJIB)

1. **Target grup kecil.** Setelah ±3 bulan data production, cek grup mana yang sudah ≥ 30 tiket FRT per 90 hari. Tetapkan targetnya **bersama pimpinan grup**, berdasarkan janji layanan, lalu isi di Admin › Groups › "Target FRT (menit)". Sampai itu dilakukan, grup tersebut memakai target global.
2. **Kalibrasi ulang target grup besar** (Customer Services 15 menit kerja; usulan CS_gajianduluan.id 1 hari kerja, Legal 2 hari kerja, Business Support 2 hari kerja) dengan data production, sekitar 1 bulan setelah go-live. Jangan dikaitkan ke penilaian kinerja sebelum itu.
3. **SLA Operational Quality Excellence.** Tiketnya tidak cocok dengan SLA mana pun, jadi tanpa jam kerja. Periksa kondisi SLA grup ini.
4. **Grup yang bekerja di luar jam kantor:** buatkan SLA dengan kalender 24/7 atau jam shift-nya (Section 22).
5. **Kalender libur** "Indonesia/Jakarta": pastikan libur nasional dan cuti bersama tahun berjalan sudah lengkap.
6. **Live chat di production:** evaluasi target chat 2 menit dengan data chat sungguhan.

### 22.4 Sumber setiap angka: ikuti setting & data SISKA yang sudah berjalan (29 Sep)

**Prinsip dari user:** ini pengembangan dari sistem yang sedang berjalan, jadi semua keputusan dan rumus disesuaikan dengan setting atau data yang sudah ada di SISKA. Angka baru hanya dibuat kalau sumbernya sama sekali tidak ada.

| Angka | Sumber | Status |
|---|---|---|
| Jam kerja | kalender SLA "Indonesia/Jakarta" + `first_response_in_min` Zammad | ikut yang ada |
| Target global FRT | `team_kpi_frt_thresholds.good_max` (240) | ikut yang ada |
| Batas sampel kecil 30 | `SMALL_SAMPLE` KPI Tim (sejak S12) | ikut yang ada |
| **Status "% sesuai target"** | `team_kpi_escalated_thresholds` (= bucket reopen bawaan Zammad 20/40/65/90), dikenakan pada **% tiket terlambat** (100 − % sesuai). Rumusnya sama dengan kartu Rasio Escalated | **diganti.** Ambang buatan 90/80/70/50 dan Setting-nya dihapus |
| **Target live chat** | `waitingListTimeout` widget chat = **4 menit**, batas antrian yang sudah berlaku sebelum customer diberi pesan timeout | **diganti** dari 2 menit |
| Target per grup | **tidak ada sumber:** 57 SLA hanya punya waktu penyelesaian, `first_response_time` kosong semua. Diturunkan dari data 90 hari, jam kerja, di titik yang sudah dicapai ±75–85% tiket | angka baru, dari data |

**Ambang status "% sesuai target"** setelah diganti:

| Status | % sesuai target |
|---|---|
| Sangat baik | > 80% (terlambat < 20%) |
| Baik | > 60% |
| Cukup | > 35% |
| Buruk | > 10% |
| Sangat buruk | ≤ 10% |

Kalau `team_kpi_escalated_thresholds` diubah, status FRT ikut berubah. API `thresholds.frt_target_met` berisi `supergood_above` / `good_above` / `ok_above` / `bad_above`.

**Hasil di staging** (180 hari, admin, target CS 15 mnt / CS_gajian 1 hari kerja / Legal & Business Support 2 hari kerja):

| Cakupan | % sesuai target | Status |
|---|---|---|
| Kartu tim | 87,1% | Sangat baik |
| Legal | 87,9% | Sangat baik |
| CS | 87,6% | Sangat baik |
| CS_gajian | 88,9% | Sangat baik |
| Business Support | 74,1% | Baik |
| Chat (90 hari, grup QA) | 95,3% (82/86) | Sangat baik |

Dengan ambang SISKA, pita "Sangat baik" lebar. Kalau tim ingin status lebih ketat, ubah `team_kpi_escalated_thresholds`; kartu Rasio Escalated juga ikut berubah.

### 22.5 Koreksi keputusan agar sesuai SISKA yang berjalan (29 Sep)

Audit menemukan beberapa keputusan hari ini yang berbeda dari setting, rumus, atau data SISKA. Atas persetujuan user, semuanya dikoreksi, kecuali dua hal yang tetap dengan alasan tertulis.

| # | Sebelumnya | Padanan di SISKA | Sesudah koreksi |
|---|---|---|---|
| 1 | target FRT per grup | 57 SLA berkondisi `ticket.help_topic`; help topic terisi di 99,9% tiket | **Dasar target default = per help topic.** Setting `team_kpi_frt_target_by_help_topic` berisi satu isian per SLA (kunci `sla_<id>`, 57 isian, dibuat ulang tiap script dijalankan) dan berlaku untuk help topic di kondisi SLA itu. Target tidak ditulis ke SLA, jadi tidak ada eskalasi baru. Opsi per grup/kanal tetap ada |
| 2 | FRT jam kerja (default) | FRT di menu Reporting (`Report::TicketFirstResponseTime`) memakai jam kalender | **Default jam kalender.** Median dashboard 180 hari **19,6 mnt = median cara Reporting 19,6 mnt**. Jam kerja tetap bisa dipilih |
| 3 | kartu B2 (% sebagai angka utama) | FRT = median + mean berdampingan (DESIGN_REPORTING_FRT Section 3) | **Kartu "First Response Time": angka utama median**, kaki "Rata-rata (mean)" + "Ada outlier" dikembalikan. Status/skala dari % sesuai target (ambang Rasio Escalated). Baris konteks: "79,6% tiket sesuai target · target per help topic · ▲ x poin". Tab Per agent: kolom "FRT median", warna dari % sesuai target. Ekspor: status ditempel ke baris median |
| 5 | status disembunyikan < 30 | KPI Tim sebelumnya: status + peringatan | **Status tetap tampil + peringatan "Sampel kecil (n < 30)"** di kartu, tabel, dan ekspor |
| 4 | live chat sejak chat dimulai | Reporting tidak memasukkan chat sama sekali | **Tetap.** Mengikuti Reporting berarti FRT chat hilang, yaitu masalah yang diperbaiki di Section 16 |
| 6 | permission `team_kpi.agents` | data laporan memakai `report` | **Tetap.** Kembali ke `report` membuka data per agent untuk seluruh role CS dan 151 customer Koordinator (Section 19) |

**Target per help topic** (dari data 90 hari, jam kalender, populasi FRT). Aturannya: langkah terkecil dari 15 mnt / 30 mnt / 1 / 2 / 4 / 8 / 12 jam / 1 / 2 / 3 / 4 hari yang saat ini sudah dicapai ≥ 75% tiket. Topik dengan kurang dari 30 tiket ikut target global 4 jam (13 topik). Semua target masih di bawah waktu penyelesaian SLA topiknya.

| Help topic | n | Median | Target | % sesuai |
|---|---|---|---|---|
| SRK | 451 | 6,4 mnt | 1 jam | 80,9% |
| SPKP | 198 | 46,8 jam | 4 hari | 82,8% |
| Gajian Duluan & KISS | 176 | 6,2 jam | 1 hari | 77,8% |
| Others | 176 | 3,1 mnt | 15 mnt | 90,3% |
| Belum Ada Kategori | 106 | 6,9 mnt | 2 jam | 75,5% |
| Penawaran Barang dan Jasa lainnya | 103 | 6,7 mnt | 15 mnt | 79,6% |
| Informasi Lowongan Pekerjaan | 97 | 9,2 mnt | 8 jam | 77,3% |
| Informasi BPJS TK | 73 | 6,7 mnt | 12 jam | 75,3% |
| Informasi Payroll | 43 | 2,3 jam | 1 hari | 93,0% |
| Informasi Karyawan | 36 | 10 mnt | 30 mnt | 83,3% |

**Hasil staging** (180 hari): median 19,6 mnt, mean 675,7 mnt (ada outlier), 79,6% sesuai target = Baik. Jumlah seluruh baris agent = tim (3.355 / 2.670). Chat (90 hari) 95,3% dengan target 4 menit.

**Konsekuensi:**
- Target grup (CS 15 mnt, CS_gajian, Legal, Business Support) tetap tersimpan tapi tidak dipakai, selama dasar target = per help topic.
- Daftar tindak lanjut production (22.3) berlaku juga untuk target per help topic: kalibrasi dengan data production, dan tetapkan target topik kecil bersama pemilik layanannya.

**Belum dikerjakan** (rumus lama yang juga belum sesuai SISKA, menunggu arahan):
- Waktu penyelesaian dibandingkan dengan target SLA per help topic (`close_in_min`).
- SLA & Backlog dikelompokkan per help topic (semua tiket berprioritas 2).
- Pola beban membaca kalender SLA, bukan hard-code.
