# Riset — Fase 4: Item No. 1 (AUX Status + Auto-distribusi Tiket)

**Status:** Riset & keputusan desain selesai (Section 4), **desain teknis rinci juga sudah selesai** (Section 5 — skema data, Service Objects, titik integrasi Transaction Backend, Scheduler, API/UI, permission) — belum ada implementasi/kode. Ditulis sebelum coding apa pun, mengikuti pola yang sama dengan Fase 3 (`docs/DESIGN_ESCALATION_STATUS.md`) — cek dulu kemungkinan native, baru putuskan bagian yang genuinely butuh custom dev.

## ⚠️ Penekanan Fungsi: Sebagian Ada Fondasi Native, Tapi Inti Requirement Tetap Custom Dev

Berbeda dengan Fase 3 (yang ternyata mayoritas native lewat Core Workflow), untuk item ini situasinya terbalik: **ada beberapa mekanisme native yang relevan sebagai fondasi**, tapi **inti dari yang diminta (status AUX granular + distribusi otomatis berbasis status itu) tetap genuinely custom dev**, karena Zammad tidak punya konsep "status agent granular" sama sekali secara native.

## 1. Yang Sudah Native (Fondasi yang Bisa Dipakai/Diperhitungkan)

### 1a. Ticket Auto Assignment (`Setting: ticket_auto_assignment`)

Zammad punya mekanisme native `Ticket#auto_assign(user)` (`app/models/ticket.rb`) — saat agent membuka sebuah tiket yang **belum ada pemiliknya** (owner_id masih "-") dari Overview yang mengaktifkan parameter `auto_assign`, dan tiket itu cocok dengan kondisi selector di Setting `ticket_auto_assignment_selector`, tiket **otomatis di-assign ke agent yang membukanya**.

- **Lokasi Setting**: area `Web::Base`, permission `admin.ticket_auto_assignment` — otomatis muncul di tab Admin > Settings > **Ticket** (tab native, bukan custom)
- **Status saat ini di staging**: `ticket_auto_assignment` = **`false`** (belum diaktifkan), `ticket_auto_assignment_selector` masih kosong
- **Sifatnya**: **reaktif/klaim** — "siapa yang buka duluan, dia yang dapat". **Bukan** distribusi proaktif berbasis status Available/Busy seperti yang diminta requirement (push tiket ke agent yang sedang Available, bukan menunggu agent buka sendiri)

### 1b. Auto-Unassign Tiket Basi (`Group#assignment_timeout`)

`Ticket.process_auto_unassign` (dipanggil Scheduler) — kalau sebuah tiket sudah di-assign ke agent tapi tidak ada perubahan selama N menit (diatur per Group, field "Assignment Timeout" di Admin > Manage > Groups), owner-nya otomatis dikembalikan ke "-" (unassigned) supaya bisa diambil ulang.

- **Sifatnya**: safety-net "lepas tiket yang keluar basi", bukan mekanisme distribusi ke agent Available

### 1c. Out of Office (`User#out_of_office`, `out_of_office_replacement_id`)

Sudah ada di native Zammad — agent bisa set rentang tanggal "sedang cuti", dengan SATU agent pengganti (replacement). Sudah dipakai proyek ini di beberapa tempat (mis. resolusi `ticket.owner` untuk notifikasi CSAT).

- **Sifatnya**: granularitas per-hari (bukan real-time per-menit), cuma 1 pengganti tetap, cuma dua kondisi (ada di kantor / cuti) — **tidak cukup** untuk kebutuhan status granular seperti "Busy Lunch 30 menit", "Busy Meeting 1 jam", dst.

### 1d. Online/Offline Presence (WebSocket, `lib/sessions.rb`)

Zammad melacak siapa yang sedang terhubung real-time (titik hijau di avatar) — tapi ini cuma **online/offline**, tidak granular, dan tidak tersimpan sebagai data historis/queryable dengan mudah (murni state koneksi WebSocket saat itu).

## 2. Yang Genuinely Butuh Custom Dev

| Bagian | Kenapa custom |
|---|---|
| **Status AUX granular** (Available / Busy Lunch / Busy Meeting / dst.) | Tidak ada konsep ini di Zammad manapun — perlu Custom Object Attribute baru di User |
| **Durasi per tipe status** (mis. Busy Lunch auto-kembali ke Available setelah 60 menit) | Perlu logic timer/expiry sendiri (kemungkinan Scheduler polling, karena tidak ada mekanisme expiry native untuk Custom Object Attribute) |
| **Distribusi tiket proaktif ke agent Available** | Native `ticket_auto_assignment` sifatnya reaktif (klaim saat dibuka), bukan push — kalau requirement-nya benar "dorong tiket baru ke agent Available", ini particle baru yang perlu dibangun dari nol (Trigger/Scheduler custom yang query status AUX lalu assign) |
| **UI cepat ganti status untuk agent** | Tidak ada widget native untuk ini — perlu komponen frontend baru (kemungkinan mirip pola dropdown kecil di header/sidebar) |

## 3. Pertanyaan Terbuka (Semua Sudah Diputuskan — lihat Section 4)

1. ~~Daftar status AUX yang pasti & durasi default~~
2. ~~Aturan routing saat ada lebih dari 1 agent Available~~
3. ~~Kalau SEMUA agent Busy/Offline, tiket diapakan~~
4. ~~Dibangun di atas `ticket_auto_assignment` native atau independen~~
5. ~~Siapa yang boleh mengubah status siapa~~
6. ~~Perubahan status perlu histori atau tidak~~

## 4. Keputusan Desain

| # | Keputusan | Detail |
|---|---|---|
| 1 | **Daftar status AUX** (set standar, bisa ditambah/diubah lewat Setting nanti) | `Available` (tanpa batas waktu), `Busy Lunch` (30 menit), `Busy Meeting` (60 menit), `Busy Training` (60 menit), `Offline` (tanpa batas waktu) |
| 2 | **Aturan routing saat >1 agent Available** | **Bisa dipilih lewat Setting**, mengikuti 3 strategi queue Asterisk PBX (lihat tabel di bawah): `leastrecent` (default), `fewestcalls`, `roundrobin` — bisa diganti-ganti tanpa deploy ulang kode |
| 3 | **Kalau semua agent Busy/Offline** | Tiket tetap dibuat sebagai **unassigned biasa** (owner "-"), diambil manual begitu ada agent yang kembali Available — tidak ada eskalasi/notifikasi khusus tambahan |
| 4 | **Basis mekanisme** | **Independen, dorong proaktif** — begitu status berubah jadi Available (atau tiket baru masuk saat sudah ada agent Available), tiket langsung didorong tanpa perlu agent membuka Overview dulu. **Tidak** dibangun di atas `ticket_auto_assignment` native (yang sifatnya reaktif/klaim) |
| 5 | **Otorisasi ubah status** | Agent bisa ubah status miliknya sendiri; **supervisor/admin juga bisa override** status agent lain (perlu permission terpisah, mis. `aux_status.override`) |
| 6 | **Histori status** | **Ya, disimpan** — tiap perubahan status dicatat dengan timestamp, untuk kebutuhan laporan produktivitas nanti (mis. total waktu Available vs Busy per agent per hari, bisa jadi kandidat card baru di KPI Tim) |

### 2a. Metode Routing yang Bisa Dipilih (Setting `aux_status_routing_method`)

Mengikuti permintaan supaya metode routing bisa diganti-ganti tanpa perlu ubah kode, disediakan 3 strategi (dropdown Setting baru, area `SISKA::AuxStatus`, sub-tab Admin > Settings > SISKA), meniru 3 strategi queue Asterisk PBX yang paling umum:

| Strategi | Basis pemilihan agent | Sumber data |
|---|---|---|
| **`leastrecent`** (default) | Agent Available yang **paling lama tidak menerima assignment tiket** (recency-based) | `MAX(tickets.last_owner_update_at)` per agent (kolom native, sudah dipakai `assignment_timeout`) — dibandingkan ke seluruh agent Available, yang nilainya paling lama (atau NULL = belum pernah dapat tiket = prioritas tertinggi) dipilih |
| **`fewestcalls`** | Agent Available dengan **beban kerja saat ini paling sedikit** — dihitung dari jumlah tiket **open aktif** (status Open/In Progress/Eskalasi) yang jadi milik agent tsb sekarang, BUKAN histori/total sepanjang waktu | `COUNT(tickets)` per agent, filter `owner_id = agent` AND state termasuk kategori `open`, dibandingkan ke seluruh agent Available, yang nilainya paling kecil dipilih |
| **`roundrobin`** | Gilir tetap berurutan mengikuti daftar agent yang sedang Available (urutan tetap, mis. berdasar `id` atau nama), lanjut dari agent terakhir yang menerima giliran | Perlu 1 nilai state tersimpan ("pointer" agent terakhir yang dapat giliran) — kandidat: field kecil di Setting/tabel konfigurasi routing (bukan per-agent, cuma 1 pointer global) |

- Setting ini **global untuk seluruh sistem** (bukan per Group/Organisasi) — cukup untuk kebutuhan saat ini, bisa diperluas ke override per-Group nanti kalau memang dibutuhkan (mengikuti pola yang sama seperti `escalation_budget_hours` di Fase 3, tapi belum diminta untuk item ini)
- Perlu dipastikan `fewestcalls` dan `leastrecent` sama-sama dihitung real-time saat proses distribusi jalan (query langsung, bukan counter yang disimpan terpisah) supaya tidak ada risiko counter basi/tidak sinkron — `roundrobin` adalah satu-satunya yang butuh state tersimpan (pointer), karena urutannya tidak bisa diturunkan dari data tiket

### Implikasi Teknis Lain (Catatan Awal, Belum Final)

- **Histori status** kemungkinan perlu tabel/Custom Object Attribute terpisah (bukan cuma 1 field "status saat ini" di User) — perlu didesain apakah pakai mekanisme History bawaan Zammad (`History` model, sudah dipakai fitur native lain) atau tabel custom sendiri
- **Durasi status dengan auto-expiry** (Busy Lunch 30 menit balik ke Available) butuh Scheduler polling berkala (mirip pola `Service::Escalation::CalculateDeadlines` di Fase 3) — cek tiap user yang statusnya sudah lewat durasi, kembalikan ke Available
- **Distribusi proaktif** butuh titik pemicu (trigger point) yang jelas: kapan tepatnya percobaan distribusi dijalankan — candidate: (a) setiap kali tiket baru masuk (via Trigger `ticket.create`), (b) setiap kali status seorang agent berubah jadi Available (kalau ada tiket unassigned menunggu), atau keduanya

---

## 5. Desain Teknis Rinci

Ditulis setelah menelusuri kode native yang relevan (`app/models/concerns/has_transaction_dispatcher.rb`, `lib/transaction_dispatcher.rb`, `app/models/transaction/*.rb`) untuk memastikan titik integrasi dipilih dari mekanisme native yang benar-benar ada, bukan tebakan.

### 5.1. Custom Object Attribute (`User`)

Dibuat lewat `ObjectManager::Attribute.add(object: 'User', ...)`, pola persis sama seperti `escalation_started_at` di Fase 3 (`script/create_escalation_object_attributes.rb`):

| Attribute | Tipe | Keterangan |
|---|---|---|
| `aux_status` | `select` | Value disinkronkan dari Setting `aux_status_types` (lihat 5.2) saat script dijalankan. Default `'available'`. `screens: {}` (disengaja — **tidak** muncul di form edit User generik, cuma bisa diubah lewat widget dropdown khusus/API baru di 5.5, sama seperti pola `escalation_started_at` yang "Internal, not editable by agents directly") |
| `aux_status_since` | `datetime` | Kapan status saat ini mulai berlaku. Diisi otomatis oleh `Service::AuxStatus::ChangeStatus` (5.3), bukan oleh user |
| `aux_status_expires_at` | `datetime`, nullable | Kapan status saat ini otomatis berakhir (`nil` untuk status tanpa batas seperti Available/Offline). Inilah kolom yang di-poll Scheduler (5.4) |

### 5.2. Setting Baru

| Setting | Area | Isi |
|---|---|---|
| `aux_status_types` | `SISKA::AuxStatus` | Array of hash: `[{value: 'available', label: 'Available', duration_minutes: nil}, {value: 'busy_lunch', label: 'Busy Lunch', duration_minutes: 30}, {value: 'busy_meeting', label: 'Busy Meeting', duration_minutes: 60}, {value: 'busy_training', label: 'Busy Training', duration_minutes: 60}, {value: 'offline', label: 'Offline', duration_minutes: nil}]`. Sumber kebenaran tunggal untuk pilihan status + durasinya — baik `ObjectManager::Attribute` (opsi dropdown) maupun `Service::AuxStatus::ChangeStatus` (kalkulasi `aux_status_expires_at`) membaca dari sini, supaya nambah/ubah status/durasi cukup lewat Admin UI, tidak perlu redeploy kode |
| `aux_status_routing_method` | `SISKA::AuxStatus` | `select`: `leastrecent` (default) / `fewestcalls` / `roundrobin` — sudah dibahas di Section 2a |
| `aux_status_roundrobin_pointer` | `SISKA::AuxStatus` | `frontend: false` (tidak muncul di Admin UI, murni state internal) — menyimpan `user_id` agent terakhir yang dapat giliran `roundrobin`. Dibaca+ditulis hanya oleh `Service::AuxStatus::SelectAgent` |

Ketiganya muncul lewat sub-tab baru **"AUX Status"** di `siska_settings.coffee` (pola yang sama seperti sub-tab "Reporting" yang sudah ada).

### 5.3. Service Objects (Ruby)

- **`Service::AuxStatus::ChangeStatus`** (`app/services/service/aux_status/change_status.rb`) — satu-satunya jalur untuk mengubah status agent (dipakai baik oleh API di 5.5 maupun oleh Scheduler expiry di 5.4):
  1. Cek otorisasi: `changed_by == target_user`, atau `changed_by.permissions?('aux_status.override')` — lempar error kalau tidak keduanya
  2. Validasi `status` ada di daftar `Setting.get('aux_status_types')`
  3. Tutup baris histori yang masih terbuka milik `target_user` (`AuxStatusLog` — 5.6): `ended_at = Time.zone.now`
  4. Buat baris histori baru: `status:, changed_by_id:, started_at: Time.zone.now`
  5. Update `target_user.aux_status`, `aux_status_since = Time.zone.now`, `aux_status_expires_at = duration_minutes ? Time.zone.now + duration_minutes.minutes : nil`
  6. Kalau `status == 'available'` → panggil `Service::AuxStatus::DistributeTicket.pending_for(target_user)` (dorong tiket unassigned yang menunggu ke agent ini, kalau ada)
- **`Service::AuxStatus::SelectAgent`** (`app/services/service/aux_status/select_agent.rb`) — terima daftar kandidat agent (User) + `group`, kembalikan satu agent terpilih sesuai `Setting.get('aux_status_routing_method')`:
  - `leastrecent`: urutkan berdasar `Ticket.where(owner_id: kandidat.id).maximum(:last_owner_update_at)` (NULL dianggap paling lama/prioritas tertinggi), ambil terkecil
  - `fewestcalls`: urutkan berdasar `Ticket.where(owner_id: kandidat.id, state_id: Ticket::State.by_category(:open)).count`, ambil terkecil
  - `roundrobin`: urutkan kandidat berdasar `id`, cari yang `id`-nya lebih besar dari `aux_status_roundrobin_pointer` (wrap-around ke awal daftar kalau tidak ada), lalu update pointer ke agent yang dipilih
- **`Service::AuxStatus::DistributeTicket`** (`app/services/service/aux_status/distribute_ticket.rb`) — dua entry point:
  - `.for_new_ticket(ticket)` — kandidat = agent dengan `aux_status = 'available'` yang punya akses ke `ticket.group` (`ticket.group.users.merge(User.where(active: true))`, filter permission `ticket.agent`), skip kalau tiket sudah ada owner atau tidak ada kandidat
  - `.pending_for(agent)` — kebalikannya: agent baru saja Available, cari 1 tiket unassigned tertua di Group yang agent itu punya akses, assign ke agent ini (bukan lewat `SelectAgent` lagi karena tujuannya sudah 1 agent spesifik)
  - Assignment sendiri = `ticket.update!(owner: agent)` — histori perubahan owner otomatis tercatat lewat mekanisme `History` bawaan Ticket (tidak perlu kode tambahan untuk ini)
- **`Service::AuxStatus::ExpireStatuses`** (`app/services/service/aux_status/expire_statuses.rb`) — dipanggil Scheduler (5.4): `User.where.not(aux_status_expires_at: nil).where(aux_status_expires_at: ..Time.zone.now)`, untuk masing-masing panggil `Service::AuxStatus::ChangeStatus` dengan `status: 'available'`, `changed_by: nil` (sistem) — **selalu kembali ke Available**, bukan Offline (sesuai keputusan Section 4: hanya status yang berdurasi/sementara yang auto-expire, Offline harus diubah manual oleh agent)

### 5.4. Scheduler

Registrasi baru lewat `script/create_aux_status_scheduler.rb`, mengikuti pola persis `create_escalation_scheduler.rb` (termasuk field `prio:` eksplisit untuk menghindari `PG::NotNullViolation` yang pernah ditemukan di Fase 3):

- **Nama**: "AUX Status: expire timed statuses"
- **Method**: `Service::AuxStatus::ExpireStatuses.run`
- **`period`**: 60 (tiap 1 menit — jauh lebih sering dari Scheduler eskalasi yang 5 menit, karena durasi status AUX paling pendek cuma 30 menit dan keterlambatan revert ke Available di sini langsung terasa oleh agent, bukan cuma metrik backend)
- **`active`**: `true` sejak awal (aman langsung aktif — analog dengan Scheduler eskalasi Fase 3, cuma menghitung ulang field internal, tidak mengirim apa pun ke customer)
- **Wajib di-deploy ke DUA container** (`zammad-staging-zammad-app-1` DAN `zammad-staging-zammad-scheduler-1`) — pelajaran dari bug Fase 3 (lihat `docs/DESIGN_ESCALATION_STATUS.md` Section 7)

### 5.5. Titik Pemicu Distribusi Proaktif — Transaction Backend (Async), Bukan Trigger

Trigger native Zammad cuma bisa menjalankan Perform action deklaratif (notifikasi, set atribut) — **tidak bisa** memanggil Ruby custom secara langsung. Titik integrasi yang benar untuk "jalankan kode custom setiap kali record Ticket/User berubah" adalah mekanisme **Transaction Backend** native (`lib/transaction_dispatcher.rb`, sudah dipakai native untuk `Transaction::Notification`, `Transaction::ClearbitEnrichment`, dst. — didaftarkan lewat Setting area `Transaction::Backend::Async`).

- Dibuat class baru `Transaction::AuxStatusDistribution` (`app/models/transaction/aux_status_distribution.rb`), didaftarkan lewat Setting baru (area `Transaction::Backend::Async`, `state: 'Transaction::AuxStatusDistribution'`) — mengikuti pola persis `Transaction::ClearbitEnrichment` (lihat `initialize(item, params)` + `perform`)
- Method `perform` menangani dua kondisi (satu class, dua cabang, karena `User` dan `Ticket` sama-sama sudah `include HasTransactionDispatcher`):
  1. `@item[:object] == 'Ticket' && @item[:type] == 'create'` → `Service::AuxStatus::DistributeTicket.for_new_ticket(ticket)`
  2. `@item[:object] == 'User' && @item[:changes]['aux_status']&.last == 'available'` → `Service::AuxStatus::DistributeTicket.pending_for(user)`
- Berjalan **async** (background job lewat `TransactionJob`, bukan blocking request agent/customer) — konsisten dengan bagaimana Notification & backend native lain juga berjalan

### 5.6. Histori Status (Tabel Baru)

Diputuskan pakai **tabel custom sendiri** (`AuxStatusLog`, model `app/models/aux_status_log.rb`) daripada mekanisme `History` bawaan Zammad — alasannya: `History` didesain untuk diff generik per-field (susah diagregasi jadi "total durasi status X per hari" tanpa pemrosesan tambahan yang rumit), sedangkan tabel dedicated dengan kolom `started_at`/`ended_at` eksplisit jauh lebih mudah untuk kebutuhan laporan produktivitas yang sudah disepakati (Section 4 poin 6).

| Kolom | Tipe | Keterangan |
|---|---|---|
| `user_id` | bigint, FK → `users` | Agent yang statusnya berubah |
| `status` | string | Snapshot value status (bukan FK ke Setting — supaya histori tetap akurat walau daftar status di Setting berubah/dihapus di kemudian hari) |
| `changed_by_id` | bigint, FK → `users`, nullable | Siapa yang mengubah — diri sendiri, supervisor (override), atau `nil` untuk auto-expire oleh sistem |
| `started_at` | datetime | Kapan status ini mulai |
| `ended_at` | datetime, nullable | Kapan status ini berakhir (`nil` = masih status aktif saat ini) |

### 5.7. API & UI Ganti Status Cepat

- **API baru**: `Api::V1::AuxStatusesController` (`app/controllers/api/v1/aux_statuses_controller.rb`) — `PUT /api/v1/aux_status` (ubah status diri sendiri) dan `PUT /api/v1/aux_status/:user_id` (override, dicek `aux_status.override` di controller) — keduanya cuma tipis, langsung panggil `Service::AuxStatus::ChangeStatus`
- **UI**: dropdown kecil baru, terintegrasi di area avatar/personal menu navigasi legacy (`app/assets/javascripts/app/controllers/_plugin/navigation.coffee` + `app/assets/javascripts/app/views/navigation/personal.jst.eco` — ditemukan sebagai titik integrasi yang sudah ada untuk menu personal agent) — dipilih karena selalu terlihat di semua halaman, bukan cuma dashboard, cocok untuk hal yang sifatnya "ganti kapan saja secara cepat"
- Override oleh supervisor (untuk agent lain) dirancang sebagai UI terpisah — kemungkinan kolom tambahan di halaman **Admin > Manage > Users** atau widget kecil di User profile, supaya tidak mengacaukan dropdown pribadi milik agent sendiri (detail UI override ini masih perlu dirinci lebih lanjut, bukan blocker untuk mulai implementasi bagian inti)

### 5.8. Permission

- **`aux_status.override`** — dibuat baru (pola sama seperti `report.unlimited_download` di Fase 3: permission baru & sempit, bukan reuse permission luas seperti `admin.user`). Agent mengubah status miliknya sendiri tidak butuh permission baru (cukup permission agent standar `ticket.agent` yang sudah dipunya semua agent)

---

## Referensi Teknis (untuk implementasi nanti)

- `app/models/concerns/has_transaction_dispatcher.rb`, `lib/transaction_dispatcher.rb`, `app/models/transaction.rb` — mekanisme Transaction Backend (sync/async), titik integrasi distribusi proaktif
- `app/models/transaction/clearbit_enrichment.rb` — contoh class backend async paling sederhana untuk dicontoh strukturnya
- `db/seeds/settings.rb` (baris registrasi `Transaction::Backend::Async`, cth. `state: 'Transaction::ClearbitEnrichment'`) — pola pendaftaran backend baru lewat Setting
- `script/create_escalation_object_attributes.rb`, `script/create_escalation_deadline_attribute.rb` — pola `ObjectManager::Attribute.add` yang sudah dipakai proyek ini (termasuk contoh `screens: {}` untuk field yang tidak boleh diedit lewat form generik)
- `db/migrate/20220517000001_create_ticket_reopen_time.rb` — contoh format `data_option` untuk `data_type: 'select'`
- `app/models/concerns/has_groups.rb` — `user.group_access?`, asosiasi `group.users` — dasar query kandidat agent per Group
- `script/create_escalation_scheduler.rb` — pola registrasi Scheduler (termasuk field `prio:` wajib) + catatan deploy ke dua container di `docs/DESIGN_ESCALATION_STATUS.md` Section 7
- `script/create_report_unlimited_download_permission.rb` — pola permission baru yang sempit/khusus

---

*Riset, keputusan desain, dan desain teknis rinci sudah selesai (Section 5). Siap lanjut ke implementasi kode.*
