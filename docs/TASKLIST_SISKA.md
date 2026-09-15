# Tasklist — Project SISKA Enhancement (Zammad)

**Basis:** [Gap_Analysis_SISKA_Requirements.xlsx](docs/Gap_Analysis_SISKA_Requirements.xlsx) & [Gap_Analysis_SISKA_Sintesis.md](docs/Gap_Analysis_SISKA_Sintesis.md)
**Urutan prioritas:** 7 → 8 → 3/12 → 1 → 5 → 6 (risiko/effort rendah → tinggi)
**Repo:** [alidjator/zammad-siska](https://github.com/alidjator/zammad-siska)

---

## Fase 0 — Kesiapan Infrastruktur

- [x] Setup repo GitHub + SSH deploy key
- [x] Push baseline source Zammad 7.1.3
- [ ] **Bereskan disk host** (saat ini ±7.6GB free dari 130GB) — blocker untuk item 7 & 8 yang butuh storage tambahan (Elasticsearch index, historical report)
- [x] Tentukan branching strategy (`main` = baseline, `feature/<no>-<nama-item>` per item gap analysis)
- [ ] Siapkan environment dev/staging terpisah untuk iterasi kode tanpa mengganggu `zammad-staging` yang sedang berjalan (agar tidak merusak instance yang sudah dipakai testing)
- [x] Definisikan alur build & deploy: edit source → `docker compose build` → redeploy container → smoke test

---

## Fase 1 — Item No. 7: Reporting Terintegrasi (Low-Medium effort)

- [ ] Konfirmasi Elasticsearch aktif & terindeks dengan benar (prasyarat Report Profiles)
- [ ] Buat/atur Report Profiles untuk metrik yang dibutuhkan (FRT, New/Open/Escalation, dll) dengan filter periode
- [ ] Evaluasi & pilih BI eksternal (Grafana atau Kibana) untuk historis >6.000 baris — sesuai rekomendasi resmi Zammad
- [ ] Rancang skema penggabungan data **Feedback Rating** dari sistem lain ke reporting terpadu (custom ETL/import script)
- [ ] Hitung kebutuhan storage untuk retensi historis 2 tahun, sesuaikan dengan kapasitas disk (lihat Fase 0)
- [ ] UAT laporan dengan stakeholder terkait (bandingkan dengan laporan sistem lama)

## Fase 2 — Item No. 8: Dashboard Realtime di Web Portal (Medium effort)

- [ ] Finalisasi daftar KPI yang ditampilkan (FRT, New/Open/Escalation, CSAT)
- [ ] Putuskan pendekatan: kombinasi Overview + Report Profile graph (tanpa coding) vs dashboard custom
- [ ] Jika custom: desain query API/Elasticsearch untuk tiap metrik
- [ ] Build frontend dashboard ringan + embed ke Web Portal
- [ ] Uji realtime-ness (polling interval / websocket) dan beban ke server

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
