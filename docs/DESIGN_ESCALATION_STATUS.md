# Desain: Status "Eskalasi" + Update Alur Status Tiket (Item No. 3 & 12 Gap Analysis)

**Status:** Seluruh bagian (1-5) **sudah diimplementasikan dan diverifikasi end-to-end** di staging — lihat Section 6 (state/trigger/Core Workflow) dan Section 7 (kalkulasi deadline, kolom Overview, card KPI Tim).
**Requirement asli:** `docs/Gap_Analysis_SISKA_Sintesis.md` No. 3 (Status Eskalasi + SLA dihitung ulang) & No. 12 (Open → In Progress → Eskalasi → Closed) — kedua item ini secara teknis identik, No. 12 mengacu langsung ke No. 3.
**Setting terkait:** `Setting.get('escalation_budget_hours')` (default `8`) — bisa diatur lewat **Admin > Settings > SISKA > Eskalasi**, atau di-override per Group/Organisasi lewat field `escalation_budget_hours` di masing-masing edit screen-nya (Group menang kalau keduanya di-set).

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
   - Ditampilkan di: kolom baru di Overview + card baru di dashboard "KPI Tim" — lihat Section 7.

---

## Pertanyaan Terbuka (sudah diputuskan seluruhnya)

1. ~~Berapa lama "budget waktu" sejak masuk Eskalasi sebelum dianggap breach?~~ **Sudah diputuskan**: 8 jam kerja (default global), bisa di-override per Group atau Organisasi — lihat Section 6.
2. ~~Sisa waktu ini mau ditampilkan di mana?~~ **Sudah diputuskan**: kombinasi kolom baru di Overview (`escalation_deadline_at`, terlihat tim sekaligus) + card baru di dashboard "KPI Tim" (agregat, "Tiket Breach Eskalasi") — lihat Section 7.
3. **Notifikasi saat breach** — belum diimplementasikan, cukup ditampilkan sebagai angka/warna saja untuk saat ini (pola state-based color yang sama dengan KPI Tim). Bisa ditambahkan Trigger notifikasi terpisah nanti kalau dibutuhkan (perlu keputusan bisnis tambahan: notifikasi ke siapa, lewat kanal apa).

---

## 6. Implementasi Bagian 1-4 (Selesai, Terverifikasi)

Sudah dibuat dan diverifikasi di staging lewat pengujian API sungguhan (bukan cuma di Rails console — lihat catatan bug di bawah, alasannya penting):

- **State**: `in progress` (id 8) dan `eskalasi` (id 9), kategori `open` — `script/create_escalation_object_attributes.rb`
- **Custom Object Attribute**: `Ticket#escalation_started_at` (datetime), `Group#escalation_budget_hours` & `Organization#escalation_budget_hours` (integer, nullable) — file yang sama
- **Setting**: `escalation_budget_hours` (default `8`), area `Escalation::Base`, muncul di **Admin > Settings > SISKA > Eskalasi** (tab baru ditambahkan ke `siska_settings.coffee`, sub-tab ketiga setelah CSAT & KPI Tim)
- **Trigger**: "Eskalasi: set escalation_started_at" — `script/create_escalation_trigger.rb`
- **Core Workflow**: "SISKA - Eskalasi must pass through In Progress" — `script/create_escalation_workflow.rb`

### Bug 1: Format `perform` Core Workflow salah — butuh key `operator` eksplisit

Percobaan pertama pakai `perform: { 'ticket.state_id' => { 'remove_option' => [9] } }` — **tidak melakukan apa-apa sama sekali**, tanpa error. Ternyata `CoreWorkflow::Result#run_backend` membaca `perform_config['operator']` untuk menentukan class backend mana yang dijalankan (`Array(perform_config['operator']).map { ... }`) — kalau key `'operator'` tidak ada, `Array(nil)` = `[]`, loop tidak pernah jalan, TIDAK ADA ERROR yang muncul. Format yang benar: `{ 'operator' => 'remove_option', 'remove_option' => [...] }` — persis pola yang dipakai contoh bawaan Zammad sendiri di `db/seeds/core_workflow.rb` (`{ 'operator' => 'show', 'show' => 'true' }`), yang seharusnya saya perhatikan lebih teliti sejak awal.

### Bug 2: Nilai `state_id` harus string, bukan integer

Setelah bug 1 diperbaiki, aturan MASIH tidak berpengaruh. Ditemukan setelah reproduksi manual langkah-demi-langkah (`CoreWorkflow::Result::RemoveOption` dipanggil langsung): `restrict_values['state_id']` berisi daftar opsi bertipe **string** (`["1", "2", ..., "9"]`, dibangun oleh `CoreWorkflow::Attributes::TicketState#values`), sedangkan `remove_option` yang saya simpan berupa **integer** (`[9]`). `Array#-` di Ruby tidak melakukan type coercion (`9 == "9"` itu `false`), jadi pengurangan tidak pernah cocok — daftar opsi tetap utuh termasuk "9". Diperbaiki dengan menyimpan semua nilai state ID sebagai string (`.to_s`) di `condition_saved` maupun `perform`.

**Pelajaran penting untuk Core Workflow rule berikutnya**: selalu simpan value ID (state/priority/dst) sebagai **string**, dan selalu sertakan key `'operator'` eksplisit di setiap `perform` action — kedua kesalahan ini **gagal senyap** (tidak ada error/exception), cuma terlihat lewat pengujian end-to-end nyata (API sungguhan), bukan dari membaca kode atau bahkan menjalankan `CoreWorkflow.perform` di Rails console tanpa membandingkan hasil `restrict_values` secara eksplisit.

**Catatan pengujian penting lainnya**: Core Workflow (`validate_workflows`) **tidak aktif** kalau tiket diubah lewat `ticket.update!` langsung di Ruby/Rails console — validasi ini cuma jalan kalau atribut `screen` di-set (biasanya oleh `TicketsController#update`, `clean_params[:screen] = 'edit'`). Jadi pengujian aturan Core Workflow **wajib** lewat API HTTP sungguhan (`PUT /api/v1/tickets/:id`) atau UI asli, bukan skrip Ruby biasa — kalau tidak, hasil pengujian akan salah (tampak "berhasil" padahal sebenarnya validasinya tidak pernah jalan).

---

## 7. Implementasi Bagian 5 (Selesai, Terverifikasi): Deadline, Overview, KPI Tim

- **Custom Object Attribute**: `Ticket#escalation_deadline_at` (datetime, nullable) — `script/create_escalation_deadline_attribute.rb`. Nilai TETAP (dihitung sekali saat masuk Eskalasi), bukan angka "sisa waktu" yang terus berkurang — supaya bisa langsung dipakai sebagai kolom Overview biasa (bisa di-sort/filter), sama seperti `escalation_at` bawaan.
- **Service kustom** `Service::Escalation::CalculateDeadlines` (`app/services/service/escalation/calculate_deadlines.rb`) — untuk tiap tiket berstatus Eskalasi yang punya `escalation_started_at`, hitung `escalation_deadline_at` = `escalation_started_at` + budget efektif (jam kerja saja, lewat mekanisme kalender bisnis yang sama dipakai SLA native — `calendar.biz.time(menit, :minutes).after(waktu_mulai)`, lihat `lib/escalation/destination_time.rb`). Budget efektif: override Group > override Organisasi > Setting global `escalation_budget_hours`. Idempotent — hanya menulis kalau nilai benar-benar berubah, dan otomatis menghitung ulang kalau tiket masuk Eskalasi lagi di kemudian hari (`escalation_started_at` di-refresh Trigger tiap kali re-entry).
- **Scheduler**: "Eskalasi: calculate escalation deadlines" — `script/create_escalation_scheduler.rb`, jalan tiap 5 menit (`period: 300`), `active: true` sejak awal (aman langsung aktif karena cuma menghitung ulang field internal, tidak mengirim apa pun ke customer, beda dengan Scheduler survei CSAT yang sengaja `active: false` sampai siap).
- **Kolom Overview**: `escalation_deadline_at` otomatis muncul di daftar "Attributes" (checkbox) saat admin membuat/mengedit Overview di **Manage > Overviews** — **murni konfigurasi, tidak perlu kode tambahan** (mekanisme checkbox-attribute Overview bawaan membaca semua Custom Object Attribute Ticket yang aktif, tidak dibatasi field `screens`). Cara pakai: Admin > Manage > Overviews > pilih/buat Overview > centang "Escalation Deadline At" di bagian Attributes.
- **Card KPI Tim baru**: "Tiket Breach Eskalasi" — jumlah tiket Eskalasi yang `escalation_deadline_at`-nya sudah lewat, dari total tiket Eskalasi saat ini (realtime, bukan window). Field baru di `Service::Dashboard::TeamKpi#call`: `eskalasi_active`, `eskalasi_breached`, `eskalasi_breach_rate_percent`, `eskalasi_breach_state`. State-based color pakai pola yang sama dengan card "Tiket Escalated" (good/ok/bad/superbad berdasarkan persentase), **tapi Setting terpisah** `team_kpi_eskalasi_breach_thresholds` (Admin > Settings > SISKA > KPI Tim) — sengaja dipisah dari `team_kpi_escalated_thresholds` karena keduanya mengukur hal yang berbeda: yang lama = breach SLA native (`escalation_at`), yang baru = breach budget kustom pasca-Eskalasi (`escalation_deadline_at`). Satu tiket bisa breach salah satu tanpa breach yang lain.

### Catatan penting: kode custom harus di-deploy ke DUA container, bukan cuma satu

`Service::Escalation::CalculateDeadlines` dipanggil oleh proses **Scheduler** (`zammad-staging-zammad-scheduler-1`), bukan oleh proses **App/Puma** (`zammad-staging-zammad-app-1`) — keduanya container terpisah dari image yang sama, tapi filesystem writable layer masing-masing terpisah. Saat file baru cuma di-`docker cp` ke container App (sesuai pola yang biasa dipakai untuk kode yang diakses lewat HTTP), Scheduler tetap gagal (`uninitialized constant`) karena filenya tidak ada di container Scheduler — Zammad sendiri mendeteksi ini lewat mekanisme retry bawaan (setelah 11 kali gagal berturut-turut, Scheduler otomatis di-nonaktifkan sendiri, `active` di-set `false`, `error_message` diisi "Failed to run ... after 11 tries"). Perbaikannya: `docker cp` file yang sama ke **kedua** container, restart keduanya, baru aktifkan ulang Scheduler-nya. **Pelajaran untuk service baru berikutnya yang dipanggil dari Scheduler**: selalu deploy ke `zammad-staging-zammad-app-1` DAN `zammad-staging-zammad-scheduler-1`, tidak cukup salah satu.

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
