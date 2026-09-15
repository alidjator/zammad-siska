# Bug Report: Timestamp SLA Ticket (`first_response_at`, `close_at`, `last_contact_at`) Bergeser ~7 Jam

**Status:** Ditemukan saat mengerjakan item No. 7 (Reporting) — First Response Time metric
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
