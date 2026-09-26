<?php

namespace Pkp\SiskaKpi;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\Factory as HttpFactory;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Http\Client\RequestException;
use Illuminate\Http\Client\Response;
use InvalidArgumentException;

/**
 * Panggilan mentah ke API KPI Tim Zammad (tanpa cache) -- pakai lewat {@see KpiService}.
 * Hasil = array dari JSON Zammad apa adanya (key snake_case); definisi field:
 * docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 1, 10, 11.
 */
class ZammadKpiClient
{
    /**
     * escalated = Rasio Escalated (%) dari snapshot per jam: riwayat baru ada sejak job snapshot
     * berjalan (history_since); unavailable = 'filters' dengan filter prioritas/channel/kategori.
     */
    public const TREND_METRICS = ['frt', 'csat', 'volume', 'resolution', 'escalated'];

    public function __construct(private readonly HttpFactory $http, private readonly array $config) {}

    /** GET /api/v1/team_kpi -- kartu KPI, antrian real-time, SLA, backlog, pembanding. */
    public function summary(KpiQuery $query): array
    {
        return $this->json('/api/v1/team_kpi', $query->toQuery());
    }

    /** GET /api/v1/team_kpi/trend -- points + comparison.points (sejajar per indeks). */
    public function trend(string $metric, KpiQuery $query): array
    {
        if (! in_array($metric, self::TREND_METRICS, true)) {
            throw new InvalidArgumentException('metric harus salah satu dari '.implode(', ', self::TREND_METRICS));
        }

        return $this->json('/api/v1/team_kpi/trend', ['metric' => $metric] + $query->toQuery());
    }

    /** GET /api/v1/team_kpi/heatmap -- 168 sel (dow ISO 1=Senin, hour 0-23). */
    public function heatmap(KpiQuery $query): array
    {
        return $this->json('/api/v1/team_kpi/heatmap', $query->toQuery());
    }

    /**
     * GET /api/v1/team_kpi/agents -- per agent (butuh token dengan permission report).
     * Tiap baris punya email untuk mencocokkan ke tabel user aplikasi; unassigned = tiket tanpa owner.
     */
    public function agents(KpiQuery $query, int $limit = 50): array
    {
        return $this->json('/api/v1/team_kpi/agents', ['limit' => $limit] + $query->toQuery());
    }

    /**
     * GET /api/v1/team_kpi/export -- .xlsx. Dengan token ber-permission report, workbook
     * menyertakan sheet Agent.
     *
     * @return array{filename: string, content: string}
     */
    public function export(KpiQuery $query): array
    {
        $response = $this->send('/api/v1/team_kpi/export', $query->toQuery());
        preg_match('/filename="?([^";]+)"?/', (string) $response->header('Content-Disposition'), $m);

        return ['filename' => $m[1] ?? 'kpi_tim.xlsx', 'content' => $response->body()];
    }

    private function json(string $path, array $query): array
    {
        return $this->send($path, $query)->json() ?? [];
    }

    private function send(string $path, array $query): Response
    {
        try {
            return $this->request()->get($path, $query)->throw();
        } catch (RequestException $e) {
            throw new ZammadKpiException("Zammad KPI {$path} gagal: HTTP {$e->response->status()}", $e->response->status(), $e);
        } catch (ConnectionException $e) {
            throw new ZammadKpiException("Zammad KPI {$path} tidak bisa dihubungi: {$e->getMessage()}", 0, $e);
        }
    }

    private function request(): PendingRequest
    {
        return $this->http
            ->baseUrl(rtrim($this->config['base_url'], '/'))
            ->withHeaders(['Authorization' => 'Token token='.$this->config['token']])
            ->acceptJson()
            ->connectTimeout($this->config['connect_timeout'] ?? 5)
            ->timeout($this->config['timeout'] ?? 30);
    }
}
