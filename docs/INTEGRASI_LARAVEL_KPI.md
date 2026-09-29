# Integrasi Aplikasi Laravel (PHP) → KPI Tim Zammad

Aplikasi kedua yang membaca KPI Tim, selain Web Portal ([`INTEGRASI_WEB_PORTAL_KPI.md`](INTEGRASI_WEB_PORTAL_KPI.md)). Keputusan:

| | Web Portal (Spring Boot) | Aplikasi Laravel |
|---|---|---|
| Akun | `integration-kpi-api@pkp.co.id` | **`integration-kpi-laravel@pkp.co.id`** (akun terpisah) |
| Permission token | `ticket.agent` | **`ticket.agent` + `team_kpi.agents`** (sebelum 29 Sep 2026: `report`; akun juga butuh role *Supervisor KPI*, lihat DESIGN_TEAM_KPI_DASHBOARD.md Section 19) |
| Data | Angka tim yang sama untuk semua staf | Angka tim **+ rekap per agent** (`/team_kpi/agents`, ekspor dengan sheet Agent) |
| Cakupan grup | 34 grup (tanpa QA) | Sama — role *Customer Services* |

Akun terpisah supaya token bisa dicabut/dirotasi tanpa mengganggu Web Portal, dan akses tercatat per aplikasi.

> **Perhatian — data pribadi.** Dengan `team_kpi.agents`, aplikasi ini menerima nama, email, dan performa (tiket, FRT, CSAT, escalated) **setiap agent**. Batasi halaman yang menampilkannya ke user yang berwenang (supervisor/manajemen) di aplikasi Laravel.

Kode: package Composer [`contrib/siska/laravel-kpi/`](../contrib/siska/laravel-kpi/) (`pkp/siska-zammad-kpi`) — PHP 8.1+, Laravel 10/11/12 (diuji dengan Laravel 12.69 / PHP 8.3).

## 1. Membuat akun & token (sekali per lingkungan)

```bash
# di container/server Zammad (staging atau production)
bundle exec rails runner script/create_kpi_integration_account.rb integration-kpi-laravel@pkp.co.id \
  "KPI Tim Laravel" ticket.agent,team_kpi.agents "KPI Tim Laravel API access"
```

Script idempoten untuk akunnya (dijalankan ulang = akun dipakai lagi, token baru dibuat). Token hanya tampil sekali — langsung simpan di secret store aplikasi Laravel. Rotasi: jalankan lagi → ganti secret → hapus token lama di Admin → API → Token Access.

Staging: akun sudah dibuat (id 77576), **tanpa token** (token uji sudah dihapus) — buat token sendiri dengan perintah di atas saat mulai integrasi.

## 2. Memasang package

`composer.json` aplikasi Laravel:

```json
"repositories": [{ "type": "path", "url": "../zammad-siska/contrib/siska/laravel-kpi" }],
"require": { "pkp/siska-zammad-kpi": "*" }
```

(atau salin folder `src/` + `config/` dan daftarkan `Pkp\SiskaKpi\ZammadKpiServiceProvider`). Service provider terdaftar otomatis (package discovery).

```bash
composer update pkp/siska-zammad-kpi
php artisan vendor:publish --tag=zammad-kpi-config   # opsional, kalau mau mengubah default
```

`.env`:

```dotenv
ZAMMAD_KPI_BASE_URL=https://helpdesk.satu.solutions
ZAMMAD_KPI_TOKEN=...            # dari langkah 1, jangan di-commit
ZAMMAD_KPI_CACHE_TTL=300        # detik, samakan dengan auto-refresh dashboard
ZAMMAD_KPI_STALE_MAX_AGE=86400  # detik, maks umur "data terakhir" saat Zammad gagal
# ZAMMAD_KPI_CACHE_STORE=redis  # default: cache store aplikasi
```

## 3. Memakai

```php
use Pkp\SiskaKpi\KpiQuery;
use Pkp\SiskaKpi\KpiService;

class KpiController extends Controller
{
    public function __construct(private KpiService $kpi) {}

    public function summary(Request $request)
    {
        // ?days=30&group_ids=2,41&channels=email&categories=complaint
        return response()->json($this->kpi->summary(KpiQuery::fromArray($request->all())));
    }

    public function agents(Request $request)   // lindungi dengan middleware/gate supervisor
    {
        $result = $this->kpi->agents(KpiQuery::fromArray($request->all()), limit: 100);
        // $result->data['agents'][i]['email'] -> cocokkan ke tabel users aplikasi
        return response()->json($result);
    }

    public function export(Request $request)
    {
        $file = $this->kpi->export(KpiQuery::fromArray($request->all()));
        return response($file['content'], 200, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => 'attachment; filename="'.$file['filename'].'"',
        ]);
    }
}
```

| Method | Zammad | Isi `->data` |
|---|---|---|
| `summary($q)` | `/api/v1/team_kpi` | Kartu KPI, real-time, SLA, backlog, `comparison` |
| `trend($metric, $q)` | `/team_kpi/trend` | `frt` / `csat` / `volume` / `resolution` / `escalated` (snapshot per jam, lihat DESIGN Section 13); `points` + `comparison.points` sejajar |
| `heatmap($q)` | `/team_kpi/heatmap` | 168 sel |
| `agents($q, $limit)` | `/team_kpi/agents` | Per agent: `name`, `email`, `tickets`, FRT median/mean/n, CSAT/n, `escalated`, `eskalasi_breached`; baris `unassigned` = tiket tanpa owner |
| `export($q)` | `/team_kpi/export` | `['filename', 'content']` — tidak di-cache |

`KpiQuery`: `days` hanya 7, 30, 90, 180, 365, 730 (selain itu `InvalidArgumentException` → balas 422). Semua method selain `export` mengembalikan `KpiResult` (`data`, `stale`, `fetchedAt`, `error`); `stale = true` = Zammad sedang gagal dan ini angka terakhir yang berhasil — tampilkan dengan keterangan, jangan kosongkan halaman. Belum pernah ada data sama sekali → `ZammadKpiException` (`->status`: 401/403 token, 422 parameter, 0 koneksi).

Catatan data sama seperti Web Portal (bagian 6 di sana): `null` = belum ada data (tampilkan "—"), FRT hanya tiket dari customer, tampilkan `n`.

## 4. Menguji

```bash
cd contrib/siska/laravel-kpi && composer install
vendor/bin/phpunit                         # 9 unit test (Http::fake)
ZAMMAD_KPI_LIVE_URL=http://localhost:3010 ZAMMAD_KPI_LIVE_TOKEN=<token> \
  vendor/bin/phpunit --group live          # ke Zammad sungguhan, termasuk agents & ekspor
```

Terakhir diuji 2026-09-26 ke staging dengan token `ticket.agent,report` akun Laravel: semua lolos (6 periode, 4 tren, heatmap, 53 agent / 90 hari, ekspor dengan sheet Agent). (Sejak 29 Sep 2026 token butuh `ticket.agent,team_kpi.agents`, bukan `report`.)
