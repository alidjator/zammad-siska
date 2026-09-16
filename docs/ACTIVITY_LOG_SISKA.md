# Log Kegiatan — Project SISKA Enhancement (Zammad)

**Diperbarui:** 2026-09-16
**Sumber:** Ringkasan seluruh item yang sudah selesai (`[x]`) di [TASKLIST_SISKA.md](TASKLIST_SISKA.md), disusun ulang sebagai catatan kegiatan pengerjaan (bukan checklist rencana). Untuk item yang masih berjalan/pending, lihat tasklist.
**Repo:** [alidjator/zammad-siska](https://github.com/alidjator/zammad-siska)

---

## Fase 0 — Kesiapan Infrastruktur

1. Setup repository GitHub untuk project ini beserta SSH deploy key, dan push baseline source Zammad 7.1.3 sebagai titik awal.
2. Membereskan disk host `Koi-Server-Dev` — free space naik dari ±7.6GB menjadi ±19GB, dengan menghapus `/home/pydev/paddle-ocr`, `/home/pydev/paddlex`, dan membersihkan cache nginx di `/var/lib/nginx/.cache`. Perlu tetap dimonitor saat masuk fase reporting/Elasticsearch karena kebutuhan storage yang lebih besar.
3. Menentukan strategi branching: `main` sebagai baseline, `feature/<no>-<nama-item>` per item gap analysis.
4. Memutuskan untuk iterasi langsung di instance `zammad-staging` yang sudah ada (tidak membuat environment dev terpisah) — konsekuensinya setiap perubahan branch fitur yang di-deploy langsung memengaruhi instance yang dipakai testing/demo, sehingga smoke test dan langkah rollback (lihat `DEVELOPMENT_WORKFLOW.md`) wajib dijalankan tiap deploy.
5. Mendefinisikan alur build & deploy: edit source → `docker compose build` → redeploy container → smoke test.

## Fase 1 — Item No. 7: Reporting Terintegrasi

6. Mengkonfirmasi Elasticsearch aktif dan terindeks dengan benar sebagai prasyarat Report Profiles — ditemukan 1.19 juta tiket ter-index, cluster health berstatus yellow (wajar untuk cluster single-node).
7. Membuat dan mengatur Report Profiles untuk metrik yang dibutuhkan: metrik First Response Time (median, dengan filter integritas data) ditambah 62 Report Profile (3 Category, 34 Group, 19 Organization), sudah live di staging.
8. Mengevaluasi dan memilih BI eksternal untuk kebutuhan historis di atas 6.000 baris (batas UI native Zammad) — **Grafana** dipilih dibanding Kibana. Container `grafana` ditambahkan ke `docker-compose.yml`, dibuatkan role Postgres read-only `grafana_ro`, data source "Zammad Postgres" disambungkan, dan starter dashboard "SISKA - Ticket & CSAT Overview" sudah dibuat.
9. **Keputusan pivot desain**: fitur Feedback Rating/CSAT dibangun **native di Zammad**, bukan integrasi/ETL dari sistem eksternal seperti rencana awal. Dibangun lengkap: Custom Object Attributes, Scheduler `Service::Csat::PrepareFeedbackSurveys`, `FeedbackController` publik, Trigger email, pengiriman multi-channel (Email/Telegram/WhatsApp di balik safety-toggle `csat_whatsapp_enabled`), dan Report adapter `Report::TicketCsatScore`. Detail lengkap ada di `docs/DESIGN_FEEDBACK_RATING.md`.
10. **Menemukan dan memperbaiki bug nyata** pada alur CSAT: link rating yang dikirim lewat Email/Telegram/WhatsApp awalnya tidak menyertakan parameter `&score=`, sehingga link yang diterima customer **selalu gagal** (langsung menampilkan halaman "link tidak valid"). Diperbaiki dengan mendesain ulang halaman feedback menjadi satu halaman interaktif: bintang rating satu baris (klik langsung tanpa reload halaman, murni CSS tanpa JavaScript) + kolom komentar (`csat_comment`, custom object attribute baru) + satu tombol kirim — menggantikan rancangan sebelumnya yang sempat berupa 5 link terpisah maupun alur 3 langkah (pilih→konfirmasi→submit). Sudah diuji end-to-end secara aman: email asli berhasil terkirim ke alamat test (`jajat.sudrajat@pkp.co.id`) dan submit rating berhasil menyimpan skor + komentar ke database.
11. Menyamakan styling halaman feedback dengan tampilan form native Zammad — warna, ukuran label, dan tombol diambil langsung dari `app/assets/stylesheets/zammad.scss` (bukan tebakan), ditambah logo SISKA (diambil dari Setting `product_logo` via endpoint publik `/api/v1/system_assets/`) dan kutipan (blockquote) bergaya native yang mengingatkan customer isi keluhan asli tiket mereka.

## Fase 2 — Item No. 8: Dashboard KPI Tim

12. **Keputusan pendekatan**: dashboard dibangun native ke Zammad sendiri yang memanggil API Zammad langsung (bukan embed Grafana/iframe) — diwujudkan sebagai tab baru "KPI Tim" di Dashboard **frontend legacy** (CoffeeScript/jQuery), karena itu yang aktif dipakai agent sekarang, bukan Vue `/desktop` yang halaman Dashboard-nya masih di-gate dev-only oleh tim Zammad.
13. Menetapkan daftar KPI final: First Response Time (median, rolling window), CSAT (rata-rata, rolling window), Tiket New & Open (snapshot realtime), Tiket Escalated (jumlah + rasio, realtime).
14. Membangun backend `Service::Dashboard::TeamKpi` + `TeamKpiController`, dengan filter periode rolling dari 7 hari sampai 2 tahun ke belakang.
15. Membangun frontend tab "KPI Tim" dengan styling native-style memakai SCSS asli (via `dartsass-rails`) — sudut kotak (bukan rounded), ikon berukuran sesuai native, grid 3 kartu per baris, dan warna ikon/angka yang **berbasis status** (supergood/good/ok/bad/superbad, mengikuti konvensi native Zammad sendiri) alih-alih warna tetap per kategori.
16. Deploy dan smoke test di staging (HTTP 200, precompile bersih, tanpa error di log), lalu commit dan push ke branch `feature/08-team-kpi-dashboard`, dan akhirnya di-**merge ke `main`**.
17. Mendokumentasikan dan memverifikasi endpoint API `GET /api/v1/team_kpi?days=N` bisa dipanggil dari aplikasi lain di luar Zammad — dibuatkan akun service khusus `integration-kpi-api@pkp.co.id` (role "Customer Services", tidak terikat ke satu orang) beserta Personal Access Token (permission `ticket.agent`), lalu diuji nyata lewat `curl` dari luar (berhasil, termasuk verifikasi field escalated konsisten di semua rentang `days`). Kontrak API (route, cara autentikasi, skema response lengkap) didokumentasikan di `docs/DESIGN_TEAM_KPI_DASHBOARD.md` Section 7.
18. Menambahkan auto-refresh berkala untuk tab "KPI Tim" — Setting baru `team_kpi_auto_refresh_seconds` (default 300 detik/5 menit, admin-editable tanpa redeploy, `0` untuk mematikan). Dipilih polling sederhana (bukan WebSocket/push) karena metriknya tidak butuh update sub-detik. Timer tetap jalan di background, tapi request AJAX cuma benar-benar dikirim kalau tab browser aktif DAN sub-tab "KPI Tim" sedang dipilih — supaya tidak boros query database saat tidak ada yang melihat. Refresh-nya silent (tanpa indikator loading, tetap tampilkan data terakhir kalau gagal). Sudah di-deploy dan diverifikasi di staging.

---

*Dokumen ini adalah snapshot per tanggal di atas. Untuk status terkini dan item yang masih berjalan, selalu rujuk ke [TASKLIST_SISKA.md](TASKLIST_SISKA.md).*
