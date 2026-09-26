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
| `GET /api/v1/team_kpi/agents` | Per owner: `tickets` (dibuat di periode), FRT median/mean/n, CSAT rata-rata/n, `escalated` & `eskalasi_breached` real-time. Owner id 1 = baris `unassigned`. **Butuh permission `report` atau `admin`** — menampilkan performa rekan kerja, jadi agent biasa hanya melihat angka tim |

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
| Agent | **Hanya untuk permission `report`/`admin`** (sama seperti `/team_kpi/agents`); agent biasa mendapat workbook tanpa sheet ini, bukan error |

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

Aplikasi kedua, **Laravel (PHP)**, memakai akun terpisah `integration-kpi-laravel@pkp.co.id` dengan token `ticket.agent` + `report` (termasuk rekap per agent): [`INTEGRASI_LARAVEL_KPI.md`](INTEGRASI_LARAVEL_KPI.md), [`contrib/siska/laravel-kpi/`](../contrib/siska/laravel-kpi/). Akun integrasi dibuat dengan `script/create_kpi_integration_account.rb` (satu akun per aplikasi, role *Customer Services*, token dibatasi ke `ticket.agent`[`,report`]). Untuk kebutuhan ini `/team_kpi/agents` sekarang juga mengembalikan `email` tiap agent (kunci stabil untuk dicocokkan ke tabel user aplikasi lain; `owner_id` hanya bermakna di Zammad).

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
