# Desain: Status "Eskalasi" + Update Alur Status Tiket (Item No. 3 & 12 Gap Analysis)

**Status:** Riset selesai, desain disepakati, **implementasi belum dimulai**.
**Requirement asli:** `docs/Gap_Analysis_SISKA_Sintesis.md` No. 3 (Status Eskalasi + SLA dihitung ulang) & No. 12 (Open → In Progress → Eskalasi → Closed) — kedua item ini secara teknis identik, No. 12 mengacu langsung ke No. 3.

---

## ⚠️ Penekanan Penting: Sebagian Requirement Ini Sebenarnya Native, Bukan Custom Dev

Gap analysis awal (`Gap_Analysis_SISKA_Sintesis.md`) mengkategorikan **kedua item ini sebagai satu paket "custom dev wajib"**, dengan alasan: *"status Eskalasi tidak otomatis memengaruhi kalkulasi SLA — arsitektural."* Ini **benar untuk bagian SLA-nya**, tapi riset lanjutan (lihat bagian 2 & 3 di bawah) menemukan bahwa **bagian "kontrol alur transisi status" (inti dari item No. 12) sebenarnya sudah tersedia native di Zammad lewat fitur Core Workflow** — tidak butuh kode sama sekali, cuma konfigurasi lewat Admin UI (`Manage > Core Workflows`).

Kemungkinan besar **ini yang tidak diketahui saat requirement awal disusun** — kalau pembuat requirement tahu Core Workflow bisa menegakkan urutan transisi status (Open → In Progress → Eskalasi → Closed, tidak boleh lompat) **dan** membatasi siapa yang boleh pindah ke status tertentu berdasarkan role, **secara server-side, bukan cuma tampilan**, kemungkinan besar item No. 12 tidak akan diajukan sebagai satu paket "custom dev" bersama No. 3 — item ini murni soal konfigurasi.

**Yang TETAP butuh custom dev (bagian No. 3 yang sebenarnya baru)**: requirement literal "SLA dihitung ulang sejak eskalasi" — yaitu ada hitungan waktu BARU yang mulai dari nol saat tiket masuk status Eskalasi (bukan cuma membekukan jam SLA lama). Ini genuinely tidak ada di Zammad manapun, perlu field custom + Trigger + Scheduler/service, dijelaskan di bagian 4.

**Ringkasan pembagian:**

| Bagian | Perlu Custom Dev? | Cara |
|---|---|---|
| Status "In Progress" & "Eskalasi" baru | **Tidak** | Manage > Ticket States (Admin UI biasa) |
| Validasi urutan transisi (tidak boleh lompat Open→Closed) | **Tidak** | Core Workflow (Manage > Core Workflows) |
| Pembatasan siapa yang boleh pindah ke Eskalasi (per role) | **Tidak** | Core Workflow, kondisi `session.role_ids` |
| Membekukan SLA native selagi status Eskalasi | **Tidak** | Checkbox `ignore_escalation` di state Eskalasi |
| **Hitungan SLA baru yang mulai dari nol sejak masuk Eskalasi** | **Ya** | Field `escalation_started_at` + Trigger (config) + Scheduler/service kalkulasi sisa waktu (custom dev) |

---

## 1. Status Baru: "In Progress" dan "Eskalasi"

Tidak ada status "In Progress" bawaan Zammad sama sekali (perlu dibuat juga, bukan cuma "Eskalasi"). Kategori state di Zammad (`new`/`open`/`pending reminder`/`pending action`/`closed`/`merged`) itu hardcoded di kode (`Ticket::StateType::CATEGORIES`), tidak bisa ditambah kategori baru tanpa mengubah core — **tapi tidak perlu**: kedua status baru ini cukup dibuat sebagai state baru di bawah kategori `open` yang sudah ada.

**Cara buat (Admin UI, no-code):** Manage > Ticket States > tambah state baru, `state_type` = "open" (kategori), untuk "In Progress" dan "Eskalasi".

Konsekuensi memilih kategori `open` untuk kedua status ini: semua mekanisme bawaan yang bernalar berdasarkan 6 kategori tadi (Overview, laporan, dashboard) akan memperlakukan tiket "In Progress"/"Eskalasi" persis seperti tiket "open" biasa — ini sudah sesuai kebutuhan (SISKA tidak minta kategori benar-benar baru, cuma nama status yang berbeda dalam alur kerja).

## 2. Validasi Urutan Transisi Status — Core Workflow, Bukan Custom Dev

Core Workflow bisa membedakan **state sebelum diedit** (`condition_saved`) dari **state yang akan disimpan** (`condition_selected`), lalu memakai aksi `remove_option`/`set_fixed_to` untuk menghilangkan pilihan status yang tidak sah dari dropdown — dan ini **ditegakkan ulang saat data disimpan ke database** (lewat `check_restrict_values`), bukan cuma disembunyikan di tampilan. Berlaku juga untuk perubahan lewat API, tidak cuma browser.

Artinya aturan seperti *"kalau status tiket saat ini Open, pilihan Closed dihilangkan dari dropdown (harus lewat In Progress → Eskalasi dulu)"* bisa dibuat murni sebagai baris konfigurasi di Manage > Core Workflows, tanpa kode. Perlu sekitar 3-4 aturan (satu per state asal) untuk mengkodekan seluruh rantai Open → In Progress → Eskalasi → Closed.

## 3. Pembatasan Berdasarkan Role — Juga Core Workflow

Core Workflow bisa membaca role user yang sedang login (`session.role_ids`) sebagai syarat tambahan. Jadi kalau nanti diputuskan "cuma Team Leader yang boleh pindahkan tiket ke Eskalasi", itu tinggal ditambahkan sebagai kondisi tambahan di aturan yang sama — **kapan saja lewat Admin UI, tanpa perlu redeploy atau ubah kode.**

**Keputusan yang sudah disepakati** (bisa diubah admin kapan saja tanpa kode):
- Aturan transisi dibuat **tanpa pembatasan role dulu** — semua Agent boleh set ke status manapun, sama seperti sekarang. Pembatasan role ditambahkan belakangan lewat UI kalau memang dibutuhkan.

## 4. SLA Native Saat Status Eskalasi

Setiap `Ticket::State` punya checkbox `ignore_escalation` — kalau dicentang pada state "Eskalasi", jam SLA bawaan Zammad (`escalation_at`, dihitung dari `created_at`, **tidak pernah reset** — ini memang arsitektural, dikonfirmasi ulang di riset ini) akan **dibekukan** selama tiket berstatus Eskalasi, bukan terus berjalan.

**Keputusan yang sudah disepakati** (bisa diubah admin kapan saja lewat Manage > Ticket States, tanpa kode): checkbox ini **dibiarkan tidak dicentang (default off)** — SLA native tetap berjalan paralel dengan jam custom baru (lihat bagian 5). Alasan: default paling aman, tidak menghilangkan data/histori SLA asli; kalau nanti dirasa membingungkan punya 2 angka sekaligus, admin tinggal centang sendiri, saya tidak perlu ubah kode.

## 5. Yang Benar-Benar Butuh Custom Dev: SLA Dihitung Ulang Sejak Eskalasi

Ini satu-satunya bagian yang genuinely tidak ada mekanisme native-nya di Zammad manapun — kalau butuh angka "sisa waktu SLA baru, dihitung dari saat tiket masuk Eskalasi (bukan dari `created_at`)", perlu dibangun sendiri:

1. **Custom Object Attribute** `escalation_started_at` (Ticket, datetime) — **konfigurasi, no-code** (Object Manager).
2. **Trigger** yang mengisi `escalation_started_at` = "sekarang", saat `state_id` berubah jadi Eskalasi. **Ini juga murni konfigurasi** (Manage > Triggers) — ditemukan dari riset bahwa Trigger native mendukung operator "relative" pada field datetime/date, dihitung real-time saat trigger benar-benar jalan (bukan nilai statis dibekukan). Catatan kecil: dropdown di UI Trigger cuma menawarkan "1-120 menit dari sekarang" (tidak ada pilihan "0"/langsung) — jadi hasilnya "sekarang + 1 menit", cukup presisi untuk SLA berskala jam/hari. `execution_condition_mode: selective` memastikan Trigger ini cuma jalan sekali saat transisi MASUK ke Eskalasi, bukan tiap kali tiket itu disave ulang.
3. **Scheduler/service kustom** (baru ini yang benar-benar custom dev) untuk menghitung sisa waktu dari `escalation_started_at` sampai batas waktu tertentu (perlu didefinisikan: berapa lama "budget" waktu sejak eskalasi sebelum dianggap breach — ini keputusan bisnis yang perlu ditentukan, lihat bagian "Pertanyaan Terbuka" di bawah).
   - **Wajib pakai kalender jam kerja yang sama dengan SLA** (`calendar.biz`, lewat `Sla.for_ticket(ticket)&.calendar&.biz`), **bukan** pengurangan waktu polos (`Time.zone.now - escalation_started_at`) — kalau tidak, hitungan custom ini akan ikut menghitung malam/akhir pekan/libur berbeda dari SLA native, jadi tidak sinkron dan membingungkan.
   - Ditampilkan di mana: belum diputuskan (opsi: widget di Ticket Zone, kolom baru di Overview, atau card baru di dashboard "KPI Tim" yang sudah ada) — lihat pertanyaan terbuka.

---

## Pertanyaan Terbuka (Perlu Diputuskan Sebelum Implementasi Bagian 5)

1. **Berapa lama "budget waktu" sejak masuk Eskalasi sebelum dianggap breach?** (mis. 4 jam kerja, 1 hari kerja — beda per Group seperti `csat_allow_rerating_on_reopen` sebelumnya, atau satu angka global?)
2. **Sisa waktu ini mau ditampilkan di mana?** Widget di halaman tiket (paling terlihat oleh agent yang menangani), kolom baru di Overview (terlihat tim sekaligus), atau card tambahan di dashboard "KPI Tim" yang sudah ada (agregat tim, bukan per-tiket)?
3. **Notifikasi saat breach** — perlu, atau cukup ditampilkan sebagai angka/warna saja (seperti pola state-based color di KPI Tim)?

---

## Referensi Teknis (untuk implementasi nanti)

- `app/models/ticket/state_type.rb` — kategori state (`CATEGORIES` hash)
- `app/models/concerns/checks_core_workflow.rb` — titik penegakan validasi Core Workflow saat save (`check_restrict_values`)
- `app/models/core_workflow/condition.rb` — `condition_saved` vs `condition_selected`
- `app/models/core_workflow/attributes/ticket_state.rb` — daftar kategori state yang bisa dijadikan opsi workflow (`open`/`closed`/`pending action`/`pending reminder` + `new` di layar create)
- `app/models/concerns/perform_changes/action/attribute_updates.rb` + `lib/time_range_helper.rb` — operator `relative` pada Trigger perform action untuk field datetime
- `app/assets/javascripts/app/controllers/_ui_element/time_range.coffee` — batas pilihan UI 1-120 (bukan 0) untuk operator relative
- `lib/escalation.rb` — `escalation_disabled?`, kalkulasi `escalation_at` dari `created_at`, efek `ignore_escalation`
- `app/models/calendar.rb` — `Calendar#biz`, engine kalender jam kerja yang harus dipakai ulang untuk kalkulasi custom
