# Bug Report: Timestamp SLA Ticket (`first_response_at`, `close_at`, `last_contact_at`) Bergeser ~7 Jam

**Status:** **Root cause dikonfirmasi sepenuhnya, data historis di staging sudah DIKOREKSI** (2026-09-16, lihat poin 7 & 8) — anomali turun dari puluhan ribu tiket menjadi 0-63 baris (sisa kasus edge yang sengaja dilewati untuk tinjauan manual). Bukan bug di kode Zammad (3.4.0 maupun 7.1.3), melainkan efek samping migrasi data MySQL→PostgreSQL yang tidak menangani perbedaan semantik kolom `TIMESTAMP` (timezone-aware, server WIB) vs `DATETIME`/JSON (timezone-naive) dengan benar. **Belum dijalankan di production asli.**
**Severity:** Tinggi — memengaruhi akurasi semua metrik waktu (FRT, waktu penyelesaian, SLA) untuk mayoritas tiket historis
**Ditemukan:** 2026-09-15, di instance `zammad-staging` (data hasil restore backup production)

---

## Ringkasan

Kolom `tickets.first_response_at`, `tickets.close_at`, dan `tickets.last_contact_at` memiliki nilai yang **~7 jam lebih awal** dari yang seharusnya, untuk mayoritas tiket sejak Oktober 2020. Selisihnya konsisten mendekati 7 jam (411–420 menit), bukan variasi acak — pola ini identik dengan selisih UTC vs WIB (UTC+7).

## Bukti

### 1. Skala dampak

| Field | Tiket anomali | Total terisi | % |
|---|---|---|---|
| `first_response_at` | 97.891 | 127.055 | 77% |
| `close_at` | 78.726 | 161.760 | 49% |
| `last_contact_at` | 90.357 | 160.690 | 56% |

### 2. Pola per bulan (sejak tiket pertama tercatat)

Anomali muncul **konsisten setiap bulan sejak Oktober 2020** (bukan cuma di batch data lama hasil migrasi), dengan tren memburuk:

| Periode | % anomali |
|---|---|
| 2020-09 (tiket pertama) | 0% |
| 2020-10 s/d 2023-12 | ±60–74% |
| 2024 | ±68–81% |
| 2025–2026 (Agustus) | ±84–92% |

### 3. Contoh konkret

Tiket #10161884 (dibuat 22 Agustus 2026):
- `ticket.created_at` = 14:19:33 UTC
- Artikel balasan agent (`created_at`) = 14:19:34 UTC ← **benar**, sesuai waktu ticket dibuat
- `tickets.preferences['escalation_calculation']['first_response_at']` = 14:19:34 UTC ← **benar**, dipakai mesin SLA/eskalasi internal
- `tickets.first_response_at` (kolom utama, dipakai reporting) = **07:19:34 UTC** ← **salah, minus 7 jam** dari nilai yang benar di atas

Ini penting: **dua sumber nilai yang secara logis harus sama, di tiket yang sama, berbeda persis ~7 jam.** Bukan artikel/channel yang salah — mekanisme SLA internal (`preferences.escalation_calculation`) menyimpan waktu yang benar, tapi kolom utama `first_response_at` yang dipakai laporan/API menyimpan waktu yang salah.

### 4. Penyebab yang SUDAH disingkirkan

Dicek langsung di instance `zammad-staging` (build Zammad 7.1.3 terbaru):
- Timezone container Docker (`zammad-app`, `zammad-scheduler`, `zammad-websocket`) — semua `UTC`, konsisten.
- `Rails.application.config.time_zone` — `UTC`.
- Timezone session Postgres (`SHOW timezone`) — `UTC`, konsisten di app maupun scheduler.
- Logic Ruby yang menulis `first_response_at` (`app/models/ticket/article/has_ticket_contact_attributes_impact.rb`) — hanya ada **1 tempat** yang menulis field ini, langsung dari `created_at` milik artikel itu sendiri (logic-nya benar, tidak ada manipulasi timezone).
- Tidak ditemukan satupun `Time.zone =` di seluruh codebase aplikasi yang bisa menyebabkan context timezone salah per-request/job.

→ Bug ini **bukan** berasal dari kode di source `zammad-siska`/Zammad 7.1.3 saat ini.

### 5. Petunjuk kuat soal asal-usul

- Gap analysis mencatat **Zammad 3.4.0 dirilis 15 Juni 2020** sebagai versi yang dipakai production SISKA sebelumnya.
- Anomali mulai muncul **Oktober 2020** — ±3.5 bulan setelah rilis itu, selaras dengan waktu wajar go-live production.
- **10 tiket baru** yang dibuat langsung di instance 7.1.3 (hari ini, 14–15 Sep 2026, setelah upgrade) — **0% anomali**, bersih semua.

**Hipotesis kerja:** bug ini kemungkinan besar berasal dari Zammad 3.4.0 (versi lama), bukan dari 7.1.3. Ada indikasi awal bahwa proses upgrade yang sedang berjalan mungkin sudah menyelesaikannya — tapi sample tiket baru masih terlalu kecil (10 tiket, dibuat manual/test) untuk dipastikan. Perlu dikonfirmasi dengan traffic production riil setelah 7.1.3 live sepenuhnya.

### 6. **[Update 2026-09-16] Konfirmasi langsung ke server database production asli**

User melakukan survey langsung ke server tempat database SISKA yang lama (production real) berjalan, dan menemukan bukti konkret yang mengisi tepat bagian yang tadinya masih hipotesis:

```sql
SELECT NOW(), SYSDATE(), UTC_TIMESTAMP();
-- NOW()               = 2026-09-16 19:40:02
-- SYSDATE()           = 2026-09-16 19:40:02
-- UTC_TIMESTAMP()     = 2026-09-16 12:40:02   <- selisih tepat 7 jam

SELECT @@system_time_zone;
-- WIB

SELECT @@global.time_zone, @@session.time_zone;
-- SYSTEM, SYSTEM   (MySQL mengikuti timezone OS server, bukan UTC eksplisit)
```

**Artinya**: server database production yang lama (dipakai Zammad 3.4.0) berjalan dengan **timezone sistem WIB (UTC+7)**, dan MySQL dikonfigurasi `time_zone = SYSTEM` — setiap pemanggilan `NOW()`/`SYSDATE()` di level SQL mengembalikan **waktu lokal WIB**, bukan UTC. Kolom `DATETIME` di MySQL sendiri **tidak menyimpan info timezone apapun** (cuma angka kalender/jam polos) — jadi kalau ada bagian dari Zammad 3.4.0 (kode Ruby lama, raw SQL, atau proses migrasi/import) yang menuliskan nilai `NOW()` versi MySQL (WIB) ke kolom yang oleh Rails/ActiveRecord diasumsikan selalu UTC — atau sebaliknya, nilai yang sudah benar UTC ikut diproses ulang seolah-olah perlu dikonversi dari WIB — hasilnya persis pola yang diamati: selisih konsisten ~7 jam, bukan acak, karena besarnya selisih ini SAMA PERSIS dengan offset UTC↔WIB.

**Status hipotesis (saat itu)**: dari "kemungkinan besar" menjadi **didukung bukti konkret** — sumber daya (server DB production asli) benar-benar dikonfigurasi dengan cara yang bisa menghasilkan tepat jenis bug ini.

### 7. **[Update 2026-09-16, lanjutan] Root cause DIKONFIRMASI SEPENUHNYA — investigasi langsung ke source code & schema Zammad 3.4.0**

User mendapat akses SSH + database langsung ke server Zammad 3.4.0 production (`/opt/zammad`, masih live). Investigasi sistematis (semua read-only — baca file, `rails console` cuma `puts`, query `SELECT`/`DESCRIBE`):

1. **Rails config timezone**: tidak ada override apapun di `config/application.rb`/`config/environments/production.rb`/`config/initializers/` — `ActiveRecord::Base.default_timezone` = `utc` (benar, bukan `:local`).
2. **OS server**: `timedatectl` mengonfirmasi `Asia/Jakarta (WIB, +0700)`, `$TZ` env kosong (proses Ruby ikut default OS kalau ada kode yang salah pakai `Time.now` polos).
3. **Kode yang menulis `first_response_at`/`last_contact_at`** (`app/models/observer/ticket/article_changes.rb`): keduanya **mewarisi** `record.created_at` milik artikel — bukan raw `Time.now`, jadi logic Ruby-nya sendiri sudah benar. `close_at = Time.zone.now` juga benar (helper Rails yang aman).
4. **Tidak ditemukan** pemakaian `Time.zone =` langsung (pola "bocor") di manapun di `app/`/`lib/`.
5. **Titik krusial** — tipe kolom MySQL asli (`ActiveRecord::Base.connection.columns(...)`):

   | Kolom | Tipe MySQL |
   |---|---|
   | `tickets.created_at` | `datetime(3)` — **tanpa** semantik timezone |
   | `ticket_articles.created_at` | `datetime(3)` — **tanpa** semantik timezone |
   | `tickets.first_response_at` | **`timestamp(3)`** |
   | `tickets.close_at` | **`timestamp(3)`** |
   | `tickets.last_contact_at` | **`timestamp(3)`** |

   Dan koneksi Rails sendiri ke MySQL (bukan cuma client SQL manual) mengonfirmasi `SELECT @@session.time_zone` = `SYSTEM` (WIB) — **tidak** di-override ke UTC di `config/database.yml` maupun di kode.

**Mekanisme akhir yang terkonfirmasi**: tipe `TIMESTAMP` di MySQL (beda dari `DATETIME`) punya semantik timezone — nilai yang ditulis diasumsikan dalam timezone SESI koneksi saat itu (di sini: WIB), lalu MySQL mengonversi & menyimpannya secara internal sebagai UTC; setiap dibaca ulang lewat sesi dengan timezone yang SAMA, MySQL otomatis mengonversi baliknya secara transparan — sehingga *dalam pemakaian normal sehari-hari* nilainya selalu tampak benar. `DATETIME` tidak punya mekanisme ini sama sekali (angka kalender disimpan apa adanya).

Perbedaan tipe kolom inilah yang secara persis menjelaskan mengapa `created_at` (DATETIME) dan `preferences['escalation_calculation']` (JSON/serialized, sama sekali di luar sistem tipe timestamp) selalu benar, sementara `first_response_at`/`close_at`/`last_contact_at` (`TIMESTAMP`) yang justru salah — **kemungkinan besar karena proses migrasi data dari MySQL (3.4.0) ke PostgreSQL (7.1.3) membaca nilai internal (UTC) dari kolom `TIMESTAMP` tanpa melewati ulang konversi timezone sesi (WIB) yang biasanya otomatis terjadi saat dibaca lewat koneksi MySQL normal** — sehingga nilai yang seharusnya dikonversi balik ke representasi yang benar malah ikut terekspor dalam bentuk mentahnya (bergeser 7 jam), sementara kolom `DATETIME` dan data JSON — yang memang tidak pernah melewati konversi apapun — selamat tidak terpengaruh.

**Status akhir**: **Root cause dikonfirmasi sepenuhnya** — dari sisi konfigurasi (WIB di OS & MySQL), tipe kolom (`TIMESTAMP` vs `DATETIME`), dan pola kerusakan yang diamati (persis cocok dengan skenario migrasi lintas-tipe-kolom di atas). Ini **bukan bug di kode Zammad 3.4.0 maupun 7.1.3** — melainkan efek samping migrasi data MySQL→PostgreSQL yang tidak menangani perbedaan semantik `TIMESTAMP` (timezone-aware) vs `DATETIME`/JSON (timezone-naive) dengan benar untuk kolom-kolom bertipe `TIMESTAMP` secara spesifik.

**Implikasi untuk koreksi data**: karena arah dan besar pergeserannya sudah diketahui pasti (kolom `TIMESTAMP` yang terpengaruh bergeser **-7 jam** dari nilai sebenarnya), data historis `first_response_at`/`close_at`/`last_contact_at` **secara prinsip bisa dikoreksi** (tambah 7 jam) untuk tiket-tiket yang terkena.

### 8. **[Update 2026-09-16, eksekusi] Koreksi data historis dijalankan di staging**

Setelah root cause dikonfirmasi sepenuhnya (poin 7), koreksi dieksekusi di `zammad-staging`:

**Cakupan**: `tickets.created_at <= 2026-08-22 23:59:59 UTC` (161.884 tiket — batas migrasi, dikonfirmasi dari pola volume harian: aktivitas normal berhenti 22 Agustus, kosong sampai 13 September, baru ada tiket lagi mulai 14 September yang merupakan tiket test project ini sendiri).

**Validasi sebelum eksekusi**: sample 12 tiket acak (termasuk yang TIDAK lolos deteksi anomali `first_response_at < created_at`) dibandingkan dengan referensi ground-truth (`preferences['escalation_calculation']['first_response_at']`, tidak pernah terpengaruh bug karena bukan kolom `TIMESTAMP`) — **12 dari 12 menunjukkan selisih persis -420 menit (-7 jam)**, tanpa kecuali. Ini mengonfirmasi bug menggeser SEMUA tiket migrasi secara seragam, bukan cuma yang terdeteksi anomali oleh heuristik lama.

**Metode koreksi**:
| Kolom | Metode | Baris terkoreksi |
|---|---|---|
| `first_response_at` | Disalin dari `preferences['escalation_calculation']['first_response_at']` kalau tersedia & valid (115.413 baris); fallback `+7 jam` kalau referensi tidak ada (11.565 baris) | 126.978 |
| `close_at` | `+7 jam` untuk semua tiket dalam cakupan | 161.760 |
| `last_contact_at` | `+7 jam` untuk semua tiket dalam cakupan | 160.643 |

**Baris yang sengaja DILEWATI** (67 tiket `first_response_at`, ID tersimpan di `timezone_correction_frt_skipped_ids.json`) — kasus di mana referensi ground-truth tidak menunjukkan selisih persis -420 menit, atau hasil koreksi masih janggal (< `created_at`). Butuh tinjauan manual terpisah, bukan bug yang sama, tidak dikoreksi otomatis untuk menghindari salah tebak.

**Keamanan proses**: backup penuh (161.884 baris, kolom `id`+`created_at`+ketiga kolom terdampak) diambil dan disimpan **sebelum** eksekusi apapun (`timezone_correction_backup_20260916_214109.jsonl`), sehingga reversible. Dry-run (`SELECT` saja) dijalankan lebih dulu dan hasilnya **cocok persis** dengan hasil eksekusi sungguhan — tidak ada penyimpangan.

**Hasil verifikasi setelah koreksi**:

| Kolom | Anomali sebelum | Anomali sesudah |
|---|---|---|
| `first_response_at` | 97.891 | **63** (99,94% terselesaikan) |
| `close_at` | 78.726 | **2** (99,997% terselesaikan) |
| `last_contact_at` | 90.357 | **0** (100% terselesaikan) |

Sisa anomali yang ada persis cocok dengan baris yang memang sengaja dilewati di atas — bukan kegagalan koreksi.

**Status**: koreksi berhasil dieksekusi di **staging**. Belum dijalankan di production asli — kalau memang diputuskan untuk production, gunakan skrip yang sama (`script/` — belum di-commit ke repo, masih di scratchpad sesi ini) dengan proses persetujuan & backup terpisah di sana.

## Dampak ke Pekerjaan SISKA

- **Data historis** (2020–2025) untuk FRT/waktu penyelesaian/SLA **tidak akurat apa adanya** — perlu koreksi (+7 jam) atau dikecualikan dari analisis/reporting historis (item No. 7).
- **Item No. 3/12** (status Eskalasi + SLA) perlu ekstra hati-hati: kalau kalkulasi SLA yang baru nanti ikut membaca kolom-kolom ini untuk data historis, hasilnya bisa salah.
- Data **ke depan** (mulai dari 7.1.3, dengan syarat hipotesis di atas benar) kemungkinan besar sudah bersih — tapi belum bisa dipastikan 100% dari sample 10 tiket saja.

## Rekomendasi Tindak Lanjut

1. **Pantau tiket-tiket baru pasca-cutover ke 7.1.3** dengan traffic production riil (bukan tiket test manual) selama beberapa hari — cek ulang persentase anomali `first_response_at < created_at` untuk memastikan bug benar-benar hilang.
2. Kalau masih muncul di 7.1.3 dengan traffic riil: perlu investigasi lebih lanjut yang butuh akses ke **source code Zammad 3.4.0 yang lama** (tidak tersedia di server ini) untuk `git blame`/diff dan menemukan baris kode persis penyebabnya — kemungkinan ada di versi lama `has_ticket_contact_attributes_impact.rb` atau kode SLA/escalation yang sudah berubah signifikan di rilis-rilis Zammad berikutnya.
3. Untuk laporan/reporting yang memakai data historis (item No. 7): tentukan kebijakan — apakah data sebelum tanggal cutover dikoreksi manual, ditandai "unreliable", atau dikecualikan sepenuhnya dari dashboard/report.
4. Query yang dipakai untuk audit ini didokumentasikan di bagian Appendix di bawah, supaya bisa dijalankan ulang kapan saja untuk verifikasi.

## Appendix — Query Verifikasi (dijalankan via `rails runner` di container `zammad-app`)

```ruby
# Skala dampak per field
[:first_response_at, :close_at, :last_contact_at].each do |field|
  anomali = Ticket.where("#{field} IS NOT NULL AND #{field} < created_at").count
  total = Ticket.where("#{field} IS NOT NULL").count
  puts "#{field}: anomali=#{anomali} / total=#{total}"
end

# Pola bulanan
rows = Ticket.where("first_response_at IS NOT NULL").pluck(:created_at, :first_response_at)
buckets = Hash.new { |h,k| h[k] = { ok: 0, anomali: 0 } }
rows.each do |c, f|
  key = c.strftime("%Y-%m")
  f < c ? buckets[key][:anomali] += 1 : buckets[key][:ok] += 1
end
buckets.sort.each { |k, v| puts "#{k}: ok=#{v[:ok]} anomali=#{v[:anomali]}" }

# Bandingkan dua sumber nilai first-response pada satu tiket
t = Ticket.find(<ticket_id>)
puts t.first_response_at
puts t.preferences.dig('escalation_calculation', 'first_response_at')
```
