# Integrasi Web Portal (Spring Boot) → KPI Tim Zammad

Gap analysis item No. 8: dashboard KPI tampil di Web Portal. Keputusan: **server Web Portal memanggil API KPI Zammad** dengan token akun integrasi, lalu menampilkannya dengan UI portal sendiri. **Semua staf melihat angka tim yang sama** (tidak per user).

Kode referensi siap pakai (Spring Boot 3.5, Java 17, juga kompatibel Boot 3.2+/4.x): [`contrib/siska/web-portal-kpi/`](../contrib/siska/web-portal-kpi/). Definisi semua field: [`DESIGN_TEAM_KPI_DASHBOARD.md`](DESIGN_TEAM_KPI_DASHBOARD.md) Section 1, 10, 11.

## 1. Alur

```
Browser staf ──(login portal)──► Web Portal (Spring Boot)
                                   │  /api/portal/kpi/*   ← PortalKpiController
                                   │  cache 5 menit + data terakhir kalau Zammad gagal (KpiService)
                                   ▼
                     Zammad /api/v1/team_kpi*  (Authorization: Token token=…)
```

- Token **hanya ada di server portal** (env var / secret store), tidak pernah dikirim ke browser.
- Karena angkanya sama untuk semua staf, portal cukup memanggil Zammad sekali per 5 menit per kombinasi filter, berapa pun staf yang membuka halaman.

## 2. Akun & token di Zammad

| | |
|---|---|
| Akun | `integration-kpi-api@pkp.co.id` (akun service, bukan akun orang), role **Customer Services** |
| Permission token | **`ticket.agent` saja** (Admin → API → Token Access, atau `Token.create!(action: 'api', persistent: true, user_id:, preferences: { permission: ['ticket.agent'] })`) |
| Cakupan angka | Grup yang bisa dibaca akun ini: 34 dari 35 grup aktif (semua kecuali **QA - Internal Testing**) — jadi tiket uji tidak ikut |
| Tidak bisa | `/team_kpi/agents` (butuh `report`/`admin`) — sesuai keputusan "angka tim yang sama": portal tidak menampilkan performa per orang. Ekspor dari akun ini juga tanpa sheet Agent |

> **Penting — cakupan grup menentukan angka.** Kalau nanti ada grup operasional baru, beri role *Customer Services* akses baca ke grup itu, kalau tidak tiketnya tidak masuk KPI portal. Field `group_ids_count` di respons `/team_kpi` bisa dipantau (saat ini `34`) untuk mendeteksi perubahan.

Rotasi token: buat token baru (`rails runner script/create_kpi_integration_account.rb integration-kpi-api@pkp.co.id "KPI Tim API" ticket.agent "KPI Tim dashboard API access"`) → ganti secret di portal → hapus token lama. Nama token saat ini: "KPI Tim dashboard API access". Aplikasi lain memakai akun sendiri — lihat [`INTEGRASI_LARAVEL_KPI.md`](INTEGRASI_LARAVEL_KPI.md).

## 3. Endpoint yang dipakai portal

| Zammad | Portal (kode referensi) | Isi |
|---|---|---|
| `GET /api/v1/team_kpi` | `GET /api/portal/kpi/summary` | Kartu KPI, antrian real-time, SLA, backlog, pembanding |
| `GET /api/v1/team_kpi/trend?metric=frt\|csat\|volume\|resolution\|escalated` | `GET /api/portal/kpi/trend?metric=` | Grafik tren + pembanding (sejajar per indeks) |
| `GET /api/v1/team_kpi/heatmap` | `GET /api/portal/kpi/heatmap` | Beban per hari × jam |
| `GET /api/v1/team_kpi/export` | `GET /api/portal/kpi/export` | Unduhan `.xlsx` (tidak di-cache) |

Parameter bersama: `days` = **7, 30, 90, 180, 365, 730** (divalidasi di `KpiQuery`), filter opsional `group_ids`, `priority_ids`, `channels`, `categories` (koma). Pembanding otomatis: < 1 tahun → periode sebelumnya, 1 tahun → tahun lalu, 2 tahun → tidak ada (`comparison: null`, data production hanya 2 tahun).

Respons portal dibungkus `KpiResult`: `{ data, stale, fetchedAt, error }`. `stale: true` = Zammad sedang gagal, `data` adalah angka terakhir yang berhasil (maks 24 jam) — tampilkan dengan keterangan "angka terakhir pukul …" (lihat artboard *kondisi data* di mockup), jangan kosongkan halaman. Kalau belum pernah ada data sama sekali → HTTP 502.

## 4. Memasang di Web Portal

1. Salin package `id.co.pkp.portal.kpi` (tanpa `KpiApplication`) ke project portal. Dependency tambahan: `com.github.ben-manes.caffeine:caffeine` (versi dikelola Spring Boot) — `spring-boot-starter-web` dan `-validation` biasanya sudah ada.
2. Aktifkan properties: `@ConfigurationPropertiesScan` di aplikasi portal, atau `@EnableConfigurationProperties(ZammadKpiProperties.class)`.
3. Konfigurasi (`application.yml`) — token dari env, jangan di-commit:
   ```yaml
   zammad:
     kpi:
       base-url: ${ZAMMAD_KPI_BASE_URL:https://helpdesk.satu.solutions}
       token: ${ZAMMAD_KPI_TOKEN}
       read-timeout: 30s
       cache-ttl: 5m
       stale-max-age: 24h
   ```
4. Lindungi `/api/portal/kpi/**` dengan autentikasi portal yang sudah ada (Spring Security), sama seperti halaman portal lain.
5. Jaringan: server portal harus bisa menjangkau Zammad lewat HTTPS (port 443).

## 5. Menguji

```bash
cd contrib/siska/web-portal-kpi
mvn test                                   # 9 unit test (MockRestServiceServer), tanpa jaringan
ZAMMAD_KPI_LIVE_URL=http://localhost:3010 ZAMMAD_KPI_LIVE_TOKEN=<token> \
  mvn test -Dtest=LiveZammadKpiIT          # uji ke Zammad sungguhan: semua periode, tren, heatmap, ekspor
```

Terakhir diuji 2026-09-26 ke staging dengan token akun integrasi: semua lolos.

## 6. Yang perlu diperhatikan di UI portal

- Angka `null` = belum ada data di periode itu → tampilkan "—", bukan 0. Di staging, akun integrasi mendapat **CSAT n = 0 di semua periode** (semua rating yang ada berasal dari tiket uji QA), dan FRT 7 hari n = 0.
- FRT dihitung hanya dari tiket yang **dibuka customer** (lihat DESIGN Section 1). Tiket yang dibuat agent (email keluar, telepon dicatat agent) tidak masuk.
- Tampilkan `n` di samping median/rata-rata; `n` kecil = angka belum bisa diandalkan.
- Tren `volume`: bucket tanpa tiket = `0`; metrik lain: bucket tanpa data = `null` (putus garis, jangan tarik ke 0).
- Kartu real-time: `realtime_comparison` (snapshot per jam ±24 jam lalu) untuk delta "vs kemarin, jam sama"; `available: false` + `reason` kalau belum ada. Tren `escalated` baru berisi sejak snapshot mulai dikumpulkan (`historySince`). Lihat DESIGN Section 13.
