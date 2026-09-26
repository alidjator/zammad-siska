<?php

namespace Pkp\SiskaKpi;

use DateTimeImmutable;
use Illuminate\Contracts\Cache\Repository as Cache;
use Illuminate\Support\Facades\Log;

/**
 * KPI untuk aplikasi: cache supaya tiap user yang membuka halaman tidak masing-masing memicu query
 * ke Zammad (ringkasan 2 tahun ±2 detik), dan fallback ke data terakhir kalau Zammad gagal.
 *
 * Dua lapis per query: "segar" (cache_ttl, default 5 menit) dan "terakhir berhasil"
 * (stale_max_age, default 24 jam). Angka tidak bergantung pada user aplikasi (satu token
 * integrasi), jadi kuncinya cukup parameter query.
 */
class KpiService
{
    private const PREFIX = 'zammad_kpi:';

    public function __construct(
        private readonly ZammadKpiClient $client,
        private readonly Cache $cache,
        private readonly array $config,
    ) {}

    public function summary(KpiQuery $query): KpiResult
    {
        return $this->cached('summary:'.$query->cacheKey(), fn () => $this->client->summary($query));
    }

    public function trend(string $metric, KpiQuery $query): KpiResult
    {
        return $this->cached("trend:{$metric}:".$query->cacheKey(), fn () => $this->client->trend($metric, $query));
    }

    public function heatmap(KpiQuery $query): KpiResult
    {
        return $this->cached('heatmap:'.$query->cacheKey(), fn () => $this->client->heatmap($query));
    }

    public function agents(KpiQuery $query, int $limit = 50): KpiResult
    {
        return $this->cached("agents:{$limit}:".$query->cacheKey(), fn () => $this->client->agents($query, $limit));
    }

    /**
     * Ekspor tidak di-cache: file harus mencerminkan kondisi saat diunduh.
     *
     * @return array{filename: string, content: string}
     */
    public function export(KpiQuery $query): array
    {
        return $this->client->export($query);
    }

    private function cached(string $key, callable $load): KpiResult
    {
        $fresh = $this->cache->get(self::PREFIX.'fresh:'.$key);
        if ($fresh !== null) {
            return $this->result($fresh, false);
        }

        try {
            $entry = ['data' => $load(), 'fetched_at' => (new DateTimeImmutable)->format(DATE_ATOM)];
        } catch (ZammadKpiException $e) {
            $last = $this->cache->get(self::PREFIX.'last:'.$key);
            if ($last === null) {
                throw $e;
            }
            Log::warning("{$e->getMessage()} -- menampilkan data terakhir dari {$last['fetched_at']}");

            return $this->result($last, true, $e->getMessage());
        }

        if (($ttl = (int) ($this->config['cache_ttl'] ?? 300)) > 0) {
            $this->cache->put(self::PREFIX.'fresh:'.$key, $entry, $ttl);
        }
        $this->cache->put(self::PREFIX.'last:'.$key, $entry, (int) ($this->config['stale_max_age'] ?? 86400));

        return $this->result($entry, false);
    }

    private function result(array $entry, bool $stale, ?string $error = null): KpiResult
    {
        return new KpiResult($entry['data'], $stale, new DateTimeImmutable($entry['fetched_at']), $error);
    }
}
