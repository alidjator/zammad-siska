# Riset — Fase 4: Item No. 1 (AUX Status + Auto-distribusi Tiket)

**Status:** Riset selesai, **keputusan desain sudah diambil** (lihat Section 4) — belum ada implementasi/kode. Ditulis sebelum coding apa pun, mengikuti pola yang sama dengan Fase 3 (`docs/DESIGN_ESCALATION_STATUS.md`) — cek dulu kemungkinan native, baru putuskan bagian yang genuinely butuh custom dev.

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
| 2 | **Aturan routing saat >1 agent Available** | **Least Recently Used** — pola yang sama dengan strategi queue `leastrecent` di Asterisk PBX: tiket didorong ke agent Available yang **paling lama TIDAK menerima assignment tiket** (bukan round-robin urutan tetap) — butuh melacak `last_assigned_at` per agent |
| 3 | **Kalau semua agent Busy/Offline** | Tiket tetap dibuat sebagai **unassigned biasa** (owner "-"), diambil manual begitu ada agent yang kembali Available — tidak ada eskalasi/notifikasi khusus tambahan |
| 4 | **Basis mekanisme** | **Independen, dorong proaktif** — begitu status berubah jadi Available (atau tiket baru masuk saat sudah ada agent Available), tiket langsung didorong tanpa perlu agent membuka Overview dulu. **Tidak** dibangun di atas `ticket_auto_assignment` native (yang sifatnya reaktif/klaim) |
| 5 | **Otorisasi ubah status** | Agent bisa ubah status miliknya sendiri; **supervisor/admin juga bisa override** status agent lain (perlu permission terpisah, mis. `aux_status.override`) |
| 6 | **Histori status** | **Ya, disimpan** — tiap perubahan status dicatat dengan timestamp, untuk kebutuhan laporan produktivitas nanti (mis. total waktu Available vs Busy per agent per hari, bisa jadi kandidat card baru di KPI Tim) |

### Implikasi Teknis dari Keputusan Ini (Catatan Awal, Belum Final)

- **Least Recently Used routing** butuh sumber kebenaran untuk "kapan agent terakhir menerima tiket" — kandidat paling sederhana: query `MAX(tickets.last_owner_update_at)` per agent (kolom ini sudah ada native di Ticket, dipakai juga oleh `assignment_timeout`), dibandingkan ke seluruh agent yang sedang `Available`, pilih yang nilainya paling lama (atau NULL = belum pernah dapat tiket sama sekali = prioritas tertinggi)
- **Histori status** kemungkinan perlu tabel/Custom Object Attribute terpisah (bukan cuma 1 field "status saat ini" di User) — perlu didesain apakah pakai mekanisme History bawaan Zammad (`History` model, sudah dipakai fitur native lain) atau tabel custom sendiri
- **Durasi status dengan auto-expiry** (Busy Lunch 30 menit balik ke Available) butuh Scheduler polling berkala (mirip pola `Service::Escalation::CalculateDeadlines` di Fase 3) — cek tiap user yang statusnya sudah lewat durasi, kembalikan ke Available
- **Distribusi proaktif** butuh titik pemicu (trigger point) yang jelas: kapan tepatnya percobaan distribusi dijalankan — candidate: (a) setiap kali tiket baru masuk (via Trigger `ticket.create`), (b) setiap kali status seorang agent berubah jadi Available (kalau ada tiket unassigned menunggu), atau keduanya

---

*Riset dan keputusan desain sudah selesai. Lanjut ke desain teknis rinci (skema data, nama Custom Object Attribute, struktur Scheduler) sebelum implementasi kode dimulai.*
