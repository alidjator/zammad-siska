# Sintesis Gap Analysis — SISKA Requirements vs Zammad

**Sumber:** `Gap_Analysis_SISKA_Requirements.xlsx`
**Scope:** Item No. 1, 3, 5, 6, 7, 8, 12
**Target platform:** Zammad 7.1.3 (custom build dari source, berjalan di Docker — stack `zammad-staging`)
**Existing platform SISKA:** Zammad 3.4.0

---

## Ringkasan

| No | Requirement | Kategori | Effort | Menyentuh Core Chat? |
|----|---|:---:|---|:---:|
| 1 | AUX status + auto-distribusi tiket | 🟡 Kuning | Medium–High | Tidak |
| 3 | Status Eskalasi + SLA dihitung ulang | 🟡 Kuning | Medium | Tidak |
| 5 | Auto-create ticket saat sesi Live Chat mulai | 🔴 Merah | High | **Ya** |
| 6 | Attachment di Live Chat | 🔴 Merah | High (berisiko) | **Ya** |
| 7 | Reporting terintegrasi, filter tanggal, historis 2 tahun | 🟡 Kuning | Low–Medium | Tidak |
| 8 | Dashboard realtime terintegrasi ke Web Portal | 🟡 Kuning | Medium | Tidak |
| 12 | Update status tiket SISKA (Open→In Progress→Eskalasi→Closed) | 🟡 Kuning | Medium | Tidak |

---

## Detail per Item

### No. 1 — AUX Status + Auto-distribusi Tiket
- **Native:** Status label per-agent (Available / Busy Lunch / dst) bisa dibuat via Custom Object Attribute di level User — konfigurasi murni, tanpa kode.
- **Custom dev wajib:** Auto-routing tiket berdasarkan status **tidak native** — tidak ada dokumentasi resmi soal presence/AUX system. Perlu Scheduler job + script API yang polling status Available lalu assign ulang tiket, plus duration mapping per tipe Busy.
- **Workaround tanpa coding:** Status jalan manual (field custom diisi agent), distribusi tiket dipantau manual oleh Team Leader lewat Overview khusus.

### No. 3 — Status "Eskalasi" + SLA Dihitung Ulang
- **Temuan kunci (dikonfirmasi dokumentasi resmi):** SLA clock Zammad **tidak pernah reset** dari `created_at`, walau tiket pindah grup/state. Ini sifat arsitektural — sama di v3.4.0 maupun v7.1.2, **bukan gap versi**.
- **Bisa dikerjakan:** State "Eskalasi" baru (Object Manager) + kondisi SLA berbeda per state — ini konfigurasi.
- **Custom dev wajib** untuk requirement literal "SLA dihitung ulang sejak eskalasi": field custom `Escalation Started At` (diisi oleh Trigger saat state berubah) + Scheduler/script yang menghitung sisa waktu dari field ini secara terpisah dari sistem SLA bawaan.
- **Workaround:** Tag "Eskalasi" + filter Overview — hanya menyelesaikan sisi identifikasi/visibility, **tidak** menyelesaikan sisi kalkulasi ulang SLA.

### No. 5 — Ticket & History Otomatis Terbentuk Saat Sesi Live Chat Dimulai
- **Temuan kunci:** Tombol "Turn chat into ticket" by design baru muncul **setelah** sesi chat selesai — ini pola desain resmi, bukan bug/limitasi versi lama.
- **Custom dev:** Perlu automation via webhook/API saat chat dibuka untuk create ticket lebih awal — effort tinggi karena menyentuh alur core channel chat, extension point resmi tidak tersedia.
- **Workaround:** SOP internal — agent klik "Turn into ticket" segera saat customer menyampaikan kebutuhan, tidak menunggu chat selesai.
- **Gap ini identik di semua versi Zammad**, termasuk 7.1.2 — bukan soal upgrade.

### No. 6 — Attachment pada Live Chat
- **Temuan kunci:** Tidak ada referensi resmi (user-docs maupun admin-docs) yang mengonfirmasi upload attachment tersedia di widget Live Chat. Permintaan fitur ini sudah ada di komunitas sejak 2018–2019 dan **belum pernah direalisasikan** di rilis manapun.
- **Custom dev:** Build widget chat kustom dengan upload capability — effort tinggi, praktis membangun ulang bagian dari core chat, bukan menambah fitur di atasnya.
- **Workaround:** Minta customer kirim attachment lewat channel lain (email ke alamat ticket, atau link cloud storage yang di-paste di chat).

### No. 7 — Reporting Terintegrasi, Filter Tanggal, Customizable, Historis 2 Tahun
- **Native (cukup kuat):** Report Profiles bawaan sudah mendukung filter periode (day/week/month/year), filter by ticket count/creation channel/communication type, download ke `.xlsx`.
- **Limitasi:** Download dibatasi maksimum **6.000 baris**; konsolidasi dengan data Feedback Rating dari sistem lain tidak otomatis.
- **Custom dev:** Untuk historis 2 tahun volume besar (>6.000 baris) dan penggabungan Feedback Rating — dokumentasi resmi Zammad **merekomendasikan BI eksternal (Grafana/Kibana)** via Elasticsearch/PostgreSQL, bukan pengembangan internal di Zammad.
- **Prasyarat konfigurasi:** Elasticsearch harus aktif (integrasi resmi ke Grafana/Kibana baru didukung mulai v4.0 — sudah terpenuhi di v7.1.3).
- **Workaround:** Report Profiles bawaan untuk kebutuhan harian/bulanan; untuk >6.000 baris, export berkala manual lalu gabung di Excel/Power BI Desktop.

### No. 8 — Dashboard Realtime Terintegrasi ke Web Portal (FRT, New/Open/Escalation, CSAT)
- **Temuan kunci:** Dashboard bawaan Zammad adalah **welcome page personal per-agent** ("memantau produktivitas sendiri dibanding rata-rata perusahaan") — bukan operational KPI board gabungan tim seperti yang diminta.
- **Custom dev:** Dashboard kustom (BI tool/custom frontend) yang query API/Elasticsearch Zammad untuk metrik gabungan (FRT, New/Open/Escalation, CSAT), lalu di-embed ke Web Portal — effort medium, sifatnya greenfield (tidak menyentuh core code Zammad).
- **Workaround:** Kombinasi Overview bawaan (dikustomisasi kolomnya, ditampilkan di monitor tim) + graph view dari Report Profiles — bukan realtime combined-KPI, tapi tanpa coding.

### No. 12 — Update Status Tiket SISKA (Open → In Progress → Eskalasi → Closed)
- **Konstrain identik dengan No. 3**: status state standar mudah dibuat (Object Manager), tapi status "Eskalasi" tidak otomatis memengaruhi kalkulasi SLA — arsitektural, sama untuk versi apapun.
- Semua kolom Impact/Custom Development/Workaround/Referensi mengacu langsung ke No. 3.

---

## Catatan Lintas-Item (Terkait Kondisi Environment Saat Ini)

1. **Source code tersedia langsung.** Image `zammad-staging-app:7.1.3` di-build dari git clone source Zammad asli (bukan image resmi `zammad/zammad`), jadi semua item custom-dev (1, 3, 5, 6, 8, 12) **teknis bisa dikerjakan langsung** di codebase Rails-nya.
2. **Trade-off upgrade.** Tim sudah melakukan upgrade Zammad manual versi-demi-versi ("hop" 4.0→6.0→7.0→7.1.3). Semakin banyak kode custom ditanam di source, semakin berat proses merge ulang di setiap hop berikutnya — terutama untuk item yang menyentuh core (No. 5, 6).
3. **Elasticsearch sudah tersedia** di stack docker (`zammad-staging-zammad-elasticsearch`), jadi prasyarat infra untuk item 7 & 8 sudah terpenuhi.
4. **Disk host kritis** — hanya ±7.6 GB free dari 130 GB. Historical reporting 2 tahun (No. 7) dan index untuk dashboard (No. 8) akan menambah beban storage signifikan; ini perlu ditangani dulu sebelum eksekusi item 7/8.
5. **No. 5 & 6 paling berisiko** — keduanya menyentuh channel Live Chat yang tidak punya extension point resmi. Custom dev di sini berpotensi jadi fork yang makin menyimpang dari upstream Zammad, bukan sekadar penambahan fitur di atasnya.

---

## Saran Urutan Prioritas Pengerjaan

**7 → 8 → 3 / 12 → 1 → 5 → 6**

Urutan ini dari risiko/effort paling rendah (konfigurasi + BI eksternal) ke paling tinggi (custom dev yang menyentuh core chat, tanpa jalur resmi yang didukung dokumentasi).
