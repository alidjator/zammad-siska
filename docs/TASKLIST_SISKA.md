# Tasklist — Project SISKA Enhancement (Zammad)

**Basis:** [Gap_Analysis_SISKA_Requirements.xlsx](docs/Gap_Analysis_SISKA_Requirements.xlsx) & [Gap_Analysis_SISKA_Sintesis.md](docs/Gap_Analysis_SISKA_Sintesis.md)
**Urutan prioritas:** 7 → 8 → 3/12 → 1 → 5 → 6 (risiko/effort rendah → tinggi)
**Repo:** [alidjator/zammad-siska](https://github.com/alidjator/zammad-siska)

---

## Fase 0 — Kesiapan Infrastruktur

- [x] Setup repo GitHub + SSH deploy key
- [x] Push baseline source Zammad 7.1.3
- [x] **Bereskan disk host** — free space naik dari ±7.6GB → ±19GB (hapus `/home/pydev/paddle-ocr`, `/home/pydev/paddlex`, clear cache nginx `/var/lib/nginx/.cache`). Tetap monitor saat masuk fase reporting/Elasticsearch (item 7/8).
- [x] Tentukan branching strategy (`main` = baseline, `feature/<no>-<nama-item>` per item gap analysis)
- [x] Keputusan: iterasi langsung di `zammad-staging` yang sudah ada (tidak bikin environment dev terpisah). Konsekuensi: setiap perubahan branch fitur yang di-deploy langsung memengaruhi instance yang dipakai testing/demo — pastikan smoke test & langkah rollback (lihat DEVELOPMENT_WORKFLOW.md) selalu dijalankan tiap deploy.
- [x] Definisikan alur build & deploy: edit source → `docker compose build` → redeploy container → smoke test

---

## Fase 1 — Item No. 7: Reporting Terintegrasi (Low-Medium effort)

- [x] Konfirmasi Elasticsearch aktif & terindeks dengan benar (prasyarat Report Profiles) — 1.19 juta tiket ter-index, cluster health yellow (normal untuk single-node)
- [x] Buat/atur Report Profiles untuk metrik yang dibutuhkan — metric FRT (median, dgn data-integrity filter) + 62 Report Profile (3 Category, 34 Group, 19 Organization) sudah live di staging
- [x] Evaluasi & pilih BI eksternal untuk historis >6.000 baris — **Grafana** dipilih (bukan Kibana). Container `grafana` ditambahkan ke `docker-compose.yml`, role Postgres read-only `grafana_ro`, data source "Zammad Postgres" tersambung, starter dashboard "SISKA - Ticket & CSAT Overview" sudah dibuat
- [x] **Keputusan pivot**: fitur **Feedback Rating/CSAT dibangun native di Zammad** (bukan integrasi/ETL dari sistem eksternal seperti rencana awal) — Object Attributes, Scheduler `Service::Csat::PrepareFeedbackSurveys`, `FeedbackController` publik, Trigger email, pengiriman multi-channel (Email/Telegram/WhatsApp di balik safety-toggle `csat_whatsapp_enabled`), Report adapter `Report::TicketCsatScore`. Lihat `docs/DESIGN_FEEDBACK_RATING.md`
- [ ] Aktifkan Scheduler CSAT ke live (saat ini `active: false`, menunggu keputusan kapan mulai kirim survey ke customer asli)
- [ ] Konfirmasi format payload WhatsApp gateway dengan tim eksternal — blocked, lihat `docs/WHATSAPP_GATEWAY_REQUIREMENTS.md`
- [ ] Hitung kebutuhan storage untuk retensi historis 2 tahun, sesuaikan dengan kapasitas disk (lihat Fase 0)
- [ ] UAT laporan dengan stakeholder terkait (bandingkan dengan laporan sistem lama)

## Fase 2 — Item No. 8: Dashboard KPI Tim (Medium effort)

- [x] **Keputusan pendekatan**: native ke Zammad sendiri, memanggil API Zammad langsung (bukan embed Grafana/iframe) — dibangun sebagai tab baru "KPI Tim" di Dashboard **frontend legacy** (CoffeeScript/jQuery), karena itu yang aktif dipakai agent sekarang, bukan Vue `/desktop` (dashboard-nya masih di-gate dev-only oleh tim Zammad)
- [x] Finalisasi daftar KPI: FRT (median, rolling window), CSAT (average, rolling window), Tiket New & Open (snapshot realtime), Tiket Escalated (count + rate, realtime)
- [x] Backend: `Service::Dashboard::TeamKpi` + `TeamKpiController`, filter periode rolling 7 hari s/d 2 tahun
- [x] Frontend: tab "KPI Tim", styling native-style via SCSS asli (`dartsass-rails`) — sudut kotak, ikon native-size, grid 3 kartu/baris, warna ikon/angka **state-based** (supergood/good/ok/bad/superbad) mengikuti konvensi native sendiri, bukan warna tetap
- [x] Deploy & smoke test di staging (HTTP 200, precompile bersih, tanpa error log), commit + push ke `feature/08-team-kpi-dashboard`
- [ ] Merge `feature/08-team-kpi-dashboard` ke `main`
- [ ] Pertimbangkan auto-refresh berkala (saat ini data hanya ter-update saat reload/ganti filter, sama seperti "My Stats" bawaan — belum ada polling)

## Fase 3 — Item No. 3 & 12: Status Eskalasi + Update Status Tiket (Medium effort)

- [ ] Buat ticket state baru **"Eskalasi"** via Object Manager
- [ ] Buat Custom Object Attribute `Escalation Started At` (timestamp)
- [ ] Buat Trigger yang mengisi `Escalation Started At` saat state berubah ke Eskalasi
- [ ] Build Scheduler/script custom untuk menghitung sisa waktu dari `Escalation Started At` (terpisah dari SLA clock bawaan)
- [ ] Wire-up transisi status penuh: Open → In Progress → Eskalasi → Closed (permission per role, validasi transisi)
- [ ] **Selaraskan ekspektasi dengan stakeholder**: SLA clock asli Zammad tidak reset — pastikan tidak ada asumsi keliru soal ini di UAT
- [ ] Testing end-to-end alur status + notifikasi terkait

## Fase 4 — Item No. 1: AUX Status + Auto-distribusi Tiket (Medium-High effort)

- [ ] Buat Custom Object Attribute status agent (dropdown: Available/Busy Lunch/dst)
- [ ] Definisikan mapping durasi per tipe status (Busy X menit, dst)
- [ ] Build Scheduler job untuk polling status agent
- [ ] Build logic/script auto-assign tiket berdasarkan status Available (perlu klarifikasi aturan routing: round-robin / load-based / lainnya)
- [ ] UI ringkas untuk agent mengubah status dengan cepat
- [ ] Testing dengan multi-agent, termasuk edge case (semua agent Busy, dll)

## Fase 5 — Item No. 5 & 6: Live Chat Enhancement (High effort, berisiko)

**Item 5 — Auto-create ticket saat chat mulai**
- [ ] Riset kode channel chat di source Zammad untuk titik hook saat sesi dibuka
- [ ] Prototype pembuatan ticket otomatis di awal sesi (hindari duplikasi dengan tombol "Turn into ticket" existing)
- [ ] Regression test menyeluruh pada fitur chat setelah perubahan

**Item 6 — Attachment di Live Chat**
- [ ] Evaluasi ulang cost/benefit — fitur ini belum pernah direalisasikan Zammad di versi manapun; pertimbangkan tetap pakai workaround (link eksternal) alih-alih custom dev
- [ ] Jika tetap dikerjakan: desain endpoint upload + perubahan widget chat frontend + penyimpanan/link ke ticket

> ⚠️ Kedua item ini menyentuh core code channel chat yang tidak punya extension point resmi — risiko konflik saat upgrade Zammad berikutnya paling tinggi di sini.

## Fase 6 — QA, Merge & Rollout

- [ ] Jalankan test suite Zammad bawaan (`test/`, `spec/`) setelah setiap perubahan
- [ ] Code review & merge tiap feature branch ke `main` satu per satu
- [ ] Rebuild image `zammad-staging-app` dari source terbaru, deploy ke container staging
- [ ] UAT bersama tim PKP di staging sebelum lanjut ke production
- [ ] Rencana migrasi/rollout ke production (mengacu pada `zammad_production_backup.sql.gz` yang sudah ada)
