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

- [x] **Bug ditemukan**: kolom `first_response_at`/`close_at`/`last_contact_at` bergeser ~7 jam untuk mayoritas tiket historis (2020-2025) — lihat `docs/BUG_REPORT_TIMEZONE_FIRST_RESPONSE.md`. Dikonfirmasi bukan berasal dari kode 7.1.3 saat ini
- [x] **Root cause dikonfirmasi SEPENUHNYA (2026-09-16)**: investigasi langsung ke server Zammad 3.4.0 production (SSH + rails console + DB, semua read-only) menemukan penyebab pastinya — kolom `tickets.first_response_at`/`close_at`/`last_contact_at` bertipe MySQL **`TIMESTAMP`** (otomatis dikonversi berdasar timezone sesi = WIB), sedangkan `created_at` bertipe **`DATETIME`** (tanpa semantik timezone) dan data `preferences` tersimpan sebagai JSON (juga tanpa semantik timezone) — keduanya karena itu selalu benar. Kesimpulan: **bukan bug di kode Zammad manapun**, melainkan efek samping migrasi data MySQL→PostgreSQL yang tidak menangani ulang konversi timezone khusus untuk kolom bertipe `TIMESTAMP`. Detail lengkap step-by-step investigasi ada di `docs/BUG_REPORT_TIMEZONE_FIRST_RESPONSE.md` poin 7
- [x] **Data historis dikoreksi di staging (2026-09-16)** — `script/fix_timezone_migration_bug.rb` dijalankan setelah dry-run (`SELECT` saja) dan backup penuh (161.884 baris). Hasil: anomali `first_response_at` 97.891→**63**, `close_at` 78.726→**2**, `last_contact_at` 90.357→**0**. Sisa anomali sengaja dilewati (kasus ambigu, ID tersimpan) untuk tinjauan manual terpisah. **Belum dijalankan di production asli** — perlu keputusan & proses persetujuan terpisah untuk itu
- [x] Konfirmasi Elasticsearch aktif & terindeks dengan benar (prasyarat Report Profiles) — 1.19 juta tiket ter-index, cluster health yellow (normal untuk single-node)
- [x] Buat/atur Report Profiles untuk metrik yang dibutuhkan — metric FRT (median, dgn data-integrity filter) + 62 Report Profile (3 Category, 34 Group, 19 Organization) sudah live di staging
- [x] Evaluasi & pilih BI eksternal untuk historis >6.000 baris — **Grafana** dipilih (bukan Kibana). Container `grafana` ditambahkan ke `docker-compose.yml`, role Postgres read-only `grafana_ro`, data source "Zammad Postgres" tersambung, starter dashboard "SISKA - Ticket & CSAT Overview" sudah dibuat
- [x] **Keputusan pivot**: fitur **Feedback Rating/CSAT dibangun native di Zammad** (bukan integrasi/ETL dari sistem eksternal seperti rencana awal) — Object Attributes, Scheduler `Service::Csat::PrepareFeedbackSurveys`, `FeedbackController` publik, Trigger email, pengiriman multi-channel (Email/Telegram/WhatsApp di balik safety-toggle `csat_whatsapp_enabled`), Report adapter `Report::TicketCsatScore`. Lihat `docs/DESIGN_FEEDBACK_RATING.md`
- [x] **Bug ditemukan & diperbaiki**: link rating di pesan Email/Telegram/WhatsApp awalnya tidak menyertakan `&score=`, sehingga link yang dikirim ke customer **selalu gagal** (langsung kena halaman "tidak valid"). Diperbaiki dengan mendesain ulang jadi satu halaman interaktif: bintang 1 baris (klik langsung, tanpa reload) + kolom komentar (`csat_comment`, custom object attribute baru) + tombol kirim tunggal — bukan 5 link terpisah maupun 3 langkah (picker→confirm→submit). Sudah diuji end-to-end (email nyata terkirim ke `jajat.sudrajat@pkp.co.id`, halaman submit berhasil menyimpan skor+komentar)
- [x] Styling halaman feedback disamakan dengan form native Zammad (warna/label/tombol diambil dari `zammad.scss`, bukan tebakan), ditambah logo SISKA (dari `product_logo` Setting via endpoint publik `/api/v1/system_assets/`) dan blockquote pengingat isi keluhan asli tiket (native blockquote style)
- [x] Commit + push perbaikan/redesign `feedback_controller.rb` ke `main`
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
- [x] Merge `feature/08-team-kpi-dashboard` ke `main`
- [x] **Dokumentasikan & verifikasi endpoint API untuk konsumsi eksternal** — `GET /api/v1/team_kpi?days=N` ternyata bisa dipanggil aplikasi lain di luar Zammad (bukan cuma dari tab dashboard-nya sendiri). Dibuatkan akun service khusus `integration-kpi-api@pkp.co.id` (role "Customer Services", tidak terikat ke satu orang) + Personal Access Token (permission `ticket.agent`), diuji nyata via `curl` dari luar — berhasil, termasuk verifikasi field escalated konsisten di semua rentang `days`. Kontrak API (route, auth, response schema) didokumentasikan lengkap di `docs/DESIGN_TEAM_KPI_DASHBOARD.md` Section 7
- [x] **Auto-refresh berkala** — Setting baru `team_kpi_auto_refresh_seconds` (default 300 detik/5 menit, `0` = mati), diterapkan via `setInterval` di `team_kpi.coffee`. Hanya benar-benar fetch data kalau tab browser aktif DAN sub-tab "KPI Tim" yang sedang dipilih (tidak boros query saat tidak dilihat), dan bersifat silent (tidak flicker loading indicator, tetap tampilkan data terakhir kalau gagal). Deployed & tested di staging
- [x] **Gap ditemukan & diperbaiki**: Setting `team_kpi_auto_refresh_seconds` (dan semua Setting CSAT) awalnya tidak bisa ditemukan lewat Admin > Settings (area custom `CSAT::Base`/`TeamKpi::Base` tidak terdaftar di tab manapun). Dibuatkan tab Admin UI baru **"SISKA"** (`app/assets/javascripts/app/controllers/_manage/siska_settings.coffee`, dengan sub-tab "CSAT" dan "KPI Tim") memakai mekanisme generik `App.SettingsArea` yang sama dengan tab System/Branding bawaan — sekarang semua 6 Setting bisa diatur lewat UI biasa, tidak perlu lagi Rails console/API
- [x] **Bug lain ditemukan & diperbaiki**: semua 6 Setting itu ternyata pakai permission `admin.setting_system` yang **tidak pernah ada** sebagai Permission asli di Zammad (`Permission.where(name: 'admin.setting_system').exists?` → `false`) — diperbaiki ke `admin.system` (permission asli yang dipakai tab "System" bawaan), di server dan di source scripts
- [x] **Bug ketiga ditemukan & diperbaiki**: `csat_feature_launched_at` dibuat tanpa `options.form`, bikin tab "SISKA > CSAT" crash total di browser ("Uncaught No such options.form for csat_feature_launched_at") — diperbaiki dengan menambahkan form definition (input text), diverifikasi ulang oleh user: tab CSAT sekarang tampil lengkap semua field dengan benar
- [x] **Semua nilai kalibrasi jadi Setting** — threshold FRT/CSAT/Escalated (sebelumnya hardcoded di `team_kpi.rb`) + `team_kpi_default_window_days` + `team_kpi_max_window_days` sekarang jadi 5 Setting baru (`team_kpi_frt_thresholds`, `team_kpi_csat_thresholds`, `team_kpi_escalated_thresholds`, `team_kpi_default_window_days`, `team_kpi_max_window_days`), semuanya bisa diatur lewat tab "SISKA > KPI Tim" tanpa redeploy. Frontend (`team_kpi.coffee`) juga dibaca dari Setting yang sama (`team_kpi_default_window_days`, via `App.Config`) supaya default dropdown tidak lagi hardcoded terpisah dan berisiko beda dengan backend. Diverifikasi via API: hasil identik dengan sebelum refactor (tidak ada perubahan perilaku, cuma jadi configurable)

## Fase 3 — Item No. 3 & 12: Status Eskalasi + Update Status Tiket (Medium effort)

- [x] **Riset teknis selesai** — ditemukan bahwa sebagian besar requirement item No. 12 (validasi urutan transisi status + pembatasan role) ternyata **native lewat Core Workflow**, bukan custom dev seperti dikira gap analysis awal. Lihat `docs/DESIGN_ESCALATION_STATUS.md` untuk pembagian lengkap native vs custom dev, referensi kode, dan 2 keputusan desain yang sudah disepakati (SLA native tetap paralel/tidak dibekukan by default via `ignore_escalation`; transisi status tanpa pembatasan role dulu) — keduanya diatur lewat Admin UI native, bukan Setting custom
- [x] Buat ticket state baru **"In Progress"** dan **"Eskalasi"** via script (kategori `open`) — `script/create_escalation_object_attributes.rb`
- [x] Buat Custom Object Attribute `escalation_started_at` (Ticket, datetime) + `escalation_budget_hours` (Group & Organization, integer nullable) — file yang sama
- [x] Buat Setting `escalation_budget_hours` (default **8 jam kerja**, global) — muncul di Admin > Settings > SISKA > Eskalasi (tab baru ditambahkan ke `siska_settings.coffee`); override per Group/Organisasi lewat field di masing-masing edit screen (Group menang kalau keduanya di-set)
- [x] Buat Trigger yang mengisi `escalation_started_at` (operator `relative`) saat state berubah ke Eskalasi — `script/create_escalation_trigger.rb`
- [x] Buat aturan Core Workflow untuk validasi urutan transisi (Open tidak boleh lompat langsung ke Eskalasi, harus lewat In Progress dulu; Closed tetap bisa dari state manapun) — `script/create_escalation_workflow.rb`
- [x] **2 bug ditemukan & diperbaiki saat implementasi Core Workflow** (keduanya gagal senyap, tanpa error): (1) format `perform` butuh key `'operator'` eksplisit, bukan langsung nama operator sebagai key; (2) nilai state ID harus string bukan integer, karena `Array#-` tidak melakukan type coercion. Ditemukan lewat reproduksi manual step-by-step, bukan dari membaca kode saja. Detail lengkap + pelajaran untuk Core Workflow rule berikutnya ada di `docs/DESIGN_ESCALATION_STATUS.md` Section 6
- [x] **Diverifikasi end-to-end lewat API sungguhan** (bukan Rails console — ditemukan Core Workflow tidak aktif kalau update lewat `ticket.update!` langsung, cuma jalan lewat controller/API asli): Open→Eskalasi langsung berhasil diblokir (HTTP 422), Open→In Progress→Eskalasi berhasil, dan `escalation_started_at` otomatis terisi
- [x] **Keputusan lokasi tampilan**: kombinasi kolom baru di Overview + card baru di dashboard "KPI Tim" (bukan widget Ticket Zone terpisah)
- [x] Buat Custom Object Attribute `escalation_deadline_at` (Ticket, datetime, nilai TETAP bukan sisa-waktu dinamis) — `script/create_escalation_deadline_attribute.rb`
- [x] Build service custom `Service::Escalation::CalculateDeadlines` — menghitung `escalation_deadline_at` = `escalation_started_at` + budget efektif (Group > Organisasi > global), **wajib pakai kalender jam kerja** `calendar.biz` (mekanisme sama dengan SLA native), bukan pengurangan waktu polos — `app/services/service/escalation/calculate_deadlines.rb`
- [x] Daftarkan Scheduler "Eskalasi: calculate escalation deadlines" (tiap 5 menit, aktif langsung) — `script/create_escalation_scheduler.rb`
- [x] **Kolom Overview** `escalation_deadline_at` — ternyata **murni konfigurasi native** (checkbox Attributes di Manage > Overviews), tidak perlu kode tambahan
- [x] **Card KPI Tim baru** "Tiket Breach Eskalasi" (jumlah tiket Eskalasi yang breach dari total aktif, state-based color) — field baru di `team_kpi.rb` + Setting terpisah `team_kpi_eskalasi_breach_thresholds` + update `team_kpi.coffee`/`team_kpi.jst.eco`
- [x] **Bug ditemukan & diperbaiki saat deploy**: kode custom yang dipanggil Scheduler harus di-deploy ke **dua container terpisah** (`zammad-app` dan `zammad-scheduler`, filesystem writable layer masing-masing beda meski image sama) — Scheduler awalnya gagal 11x berturut-turut lalu auto-nonaktif sendiri (perilaku bawaan Zammad) sebelum file di-copy ke container Scheduler juga. Detail di `docs/DESIGN_ESCALATION_STATUS.md` Section 7
- [x] **Diverifikasi end-to-end di staging**: kalkulasi jam-kerja diuji manual (tiket masuk Eskalasi di luar jam kerja → deadline jatuh ke jam kerja berikutnya, sesuai ekspektasi), override Group diuji & di-revert, dan Scheduler dikonfirmasi jalan sendiri lewat siklus pollingnya (`status: "ok"`, tanpa error) setelah deploy ke kedua container
- [ ] **Selaraskan ekspektasi dengan stakeholder**: SLA clock asli Zammad tidak reset — pastikan tidak ada asumsi keliru soal ini di UAT
- [ ] Notifikasi saat breach — belum diimplementasikan (saat ini cukup indikator angka/warna di KPI Tim), bisa ditambahkan nanti kalau dibutuhkan (perlu keputusan bisnis: notifikasi ke siapa, lewat kanal apa)
- [ ] Testing end-to-end alur status + notifikasi terkait (UAT bersama stakeholder)

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

## Di Luar Fase — Anonimisasi Kontak User Non-Admin (Staging)

- [x] **Anonimisasi permanen email/login/phone/mobile untuk 72.017 user non-admin** di staging (`zammad-staging-zammad-app-1`), setelah komplain email testing "nyasar" ke customer asli — ditemukan database staging adalah salinan penuh data production dengan SMTP outbound hidup, bukan data dummy
- [x] Scope: semua user kecuali role Admin, akun sistem (id 1), dan domain `@pkp.co.id` (staf internal PKP + akun service `integration-kpi-api@pkp.co.id`)
- [x] Backup otomatis nilai lama (72.017 baris) tersimpan sebelum eksekusi, dieksekusi lewat SQL mentah (tanpa callback/notifikasi apa pun) — `script/anonymize_non_admin_contacts.rb`
- [x] Dijalankan manual oleh user (eksekusi tulis massal diblokir untuk Claude oleh auto-mode classifier, sesuai pola yang sama dengan koreksi bug timezone sebelumnya)
- [x] Didokumentasikan lengkap (kriteria scope, format transformasi, contoh before/after ter-mask) di `docs/ANONYMIZATION_CONTACT_INFO.md`
- [ ] **Belum diproses**: identitas Telegram (tidak ada kolom per-user yang stabil, kemungkinan cuma ada di `ticket_articles.preferences` per pesan — butuh investigasi terpisah)
- [ ] Pindahkan file backup (`/tmp/anonymize_contacts_backup_20260917_010218.jsonl`, berisi PII asli) dari `/tmp` container ke penyimpanan permanen yang aman, di luar git — `/tmp` container bisa hilang kalau container di-recreate
