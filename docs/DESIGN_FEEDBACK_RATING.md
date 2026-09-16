# Desain: Feedback Rating (CSAT) Native di Zammad

**Status:** Requirement baru (bukan bagian dari 18 item gap analysis awal) — saat ini Feedback Rating berasal dari integrasi sistem lain, target: jadi bagian native Zammad.
**Terkait:** Item No. 7 (Reporting) & No. 8 (Dashboard) — CSAT jadi salah satu input metrik di keduanya.

---

## 1. Ringkasan Requirement

Setelah tiket **closed**, customer perlu bisa memberi rating kepuasan (CSAT) langsung dari dalam ekosistem Zammad — tanpa bergantung pada sistem eksternal. Rating ini kemudian harus bisa dilaporkan (rata-rata/median per agent, grup, periode) di Reports & Dashboard.

## 2. Riset: Mekanisme Zammad yang Bisa Dipakai Ulang

Dicek langsung ke source `zammad-staging` — dua primitive inti Zammad sudah menyediakan hampir semua yang dibutuhkan, sehingga custom dev bisa diminimalkan:

### a. Model `Token` (`app/models/token.rb`)
Sudah dipakai Zammad untuk password reset & API token. Fitur yang relevan:
- `Token.create(action: '<nama>', user_id:, expires_at:, preferences: {...})` — generate token random aman (`SecureRandom.urlsafe_base64(48)`).
- `Token.check(action:, token:)` — validasi token, otomatis invalid kalau lewat `expires_at`.
- `preferences` (jsonb) bisa dipakai nyimpen `ticket_id` yang terkait token itu.

→ **Tidak perlu bikin mekanisme token/keamanan dari nol** — tinggal pakai `action: 'CustomerFeedback'`.

### b. `FormController` (`app/controllers/form_controller.rb`)
Ini controller publik (tanpa login) yang SUDAH ADA di Zammad inti — dipakai untuk form pembuatan tiket dari luar (`embed.js`). Pola yang relevan untuk ditiru:
- `skip_before_action :verify_csrf_token` + CORS preflight handling — pola standar Zammad untuk endpoint publik.
- Validasi token sebelum proses apapun.
- Response JSON sederhana.

→ Endpoint submit rating bisa dibuat dengan pola yang **identik**, bukan pola baru yang belum pernah diuji di codebase ini.

### c. Custom Object Attribute (Object Manager)
Sudah dipakai di beberapa gap analysis item lain (No. 1, 3, 12) — field baru di level Ticket, config murni lewat Admin UI, otomatis searchable/filterable/reportable.

### d. Trigger
Untuk kirim email survey ke customer setelah tiket closed — **tidak perlu kode**, cukum kondisi `ticket.state_id is closed` + action kirim notifikasi/artikel ke customer, isi & waktu kirim diatur admin lewat UI.

---

## 3. Arsitektur yang Diusulkan

```
Ticket closed
     │
     ▼
[Scheduler job - CUSTOM DEV, kecil]
  - Cek tiket closed yang belum ada feedback token
  - Token.create(action: 'CustomerFeedback', preferences: { ticket_id: })
  - Isi Custom Object Attribute "Feedback Link" di tiket dgn URL bertoken
     │
     ▼
[Trigger - NO CODE, admin-configurable]
  - Kondisi: state=closed AND "Feedback Link" terisi AND "Feedback Email Sent" kosong
  - Aksi: kirim email ke customer, body template pakai placeholder Feedback Link
     │
     ▼
Customer klik salah satu link rating (1-5) di email
     │
     ▼
[FeedbackController#submit - CUSTOM DEV, meniru pola FormController]
  - Validasi via Token.check(action: 'CustomerFeedback', token: params[:token])
  - Simpan skor ke Custom Object Attribute "CSAT Score" + "CSAT Submitted At"
  - Token dihabiskan (single-use)
  - Render halaman "Terima kasih" sederhana
     │
     ▼
Data CSAT otomatis reportable (Object Attribute native ke Overview/Report)
     │
     ▼
[Report adapter baru - CUSTOM DEV, kecil, sama polanya dgn Report::TicketFirstResponseTime
 yang sudah dibuat untuk item No. 7] → metrik CSAT Average/Median di Manage > Reports
```

### Custom Object Attribute yang dibutuhkan (Object Manager, no-code)
| Field | Tipe | Catatan |
|---|---|---|
| `csat_score` | Integer/Select (1-5) | Skor rating |
| `csat_submitted_at` | Datetime | Kapan customer submit |
| `csat_feedback_link` | Text (internal-only, hidden dari customer) | URL bertoken, diisi scheduler |
| `csat_email_sent_at` | Datetime | Penanda supaya Trigger tidak kirim dobel |

### Endpoint publik baru (custom dev)
- `GET /feedback/:ticket_id?token=...&score=N` — one-click link per skor (1-5), langsung simpan rating begitu diklik dari email (tanpa perlu halaman form terpisah untuk MVP). Opsional: setelah klik, tampilkan halaman "mau tambah komentar?" untuk elaborasi (iterasi berikutnya, bukan MVP).

## 4. Pembagian Effort

| Bagian | Jenis | Effort |
|---|---|---|
| Custom Object Attribute (4 field) | Konfigurasi (Object Manager) | Kecil |
| Trigger kirim email survey | Konfigurasi (Admin UI) | Kecil |
| Scheduler job generate token + isi link | **Custom dev** | Kecil-Medium (~1 file, mirip pola Scheduler yang sudah ada di codebase) |
| `FeedbackController` + route publik | **Custom dev** | Medium (meniru `FormController`, tapi lebih simpel karena cuma 1 aksi: simpan skor) |
| Report adapter CSAT Average/Median | **Custom dev** | Kecil (mirror `Report::TicketFirstResponseTime` yang sudah ada) |
| Halaman "Terima kasih" publik | Frontend sederhana (HTML statis/ERB) | Kecil |

**Total: didominasi konfigurasi + 3 file custom dev kecil-menengah** — jauh lebih ringan dibanding perkiraan awal karena bisa menumpang pada `Token` model dan pola `FormController` yang sudah teruji di codebase ini.

## 5. Pertimbangan & Risiko

1. **Token single-use vs re-submit**: perlu keputusan bisnis — kalau customer klik link rating dua kali (misal salah pencet), apakah overwrite skor sebelumnya atau ditolak? Rekomendasi: izinkan overwrite selama token belum expired, supaya tidak membingungkan customer.
2. **Expiry window**: berapa lama link rating berlaku setelah tiket closed? Rekomendasi 14-30 hari (`Token#expires_at`), sesuaikan kebutuhan bisnis.
3. **Tiket reopen setelah rating**: kalau tiket dibuka lagi setelah dirating lalu ditutup lagi, apakah minta rating baru? Perlu direset `csat_email_sent_at`/`csat_feedback_link` saat state kembali ke closed dari selain closed.
4. **Bahasa & channel**: desain ini asumsi channel utama email. Kalau butuh juga via WhatsApp/chat (SISKA juga pakai chat), perlu channel pengiriman link tambahan — Trigger Zammad hanya native untuk email; channel lain butuh integrasi terpisah.
5. **Abuse/spam link**: karena `GET` request langsung menyimpan skor tanpa konfirmasi tambahan, ada risiko link ke-preview/ke-crawl oleh email client/security scanner yang otomatis membuka semua link (submit skor palsu). Mitigasi: token single-use + toleransi kalau ada 2x hit dalam beberapa detik (asumsikan prefetch), atau tetap tampilkan halaman konfirmasi (bukan langsung simpan di response pertama) — trade-off kesederhanaan vs akurasi data.

## 6. Langkah Berikutnya

1. Konfirmasi keputusan bisnis di poin 5 (Pertimbangan & Risiko) sebelum mulai implementasi.
2. Buat branch `feature/csat-native`.
3. Urutan build: Custom Object Attribute → Scheduler job token → FeedbackController → Trigger → Report adapter.
4. Uji end-to-end di staging sebelum dianggap selesai.
