<?php

namespace Pkp\SiskaKpi\Tests;

use PHPUnit\Framework\Attributes\Group;
use Pkp\SiskaKpi\KpiQuery;
use Pkp\SiskaKpi\ZammadKpiClient;

/**
 * Uji ke Zammad sungguhan:
 * ZAMMAD_KPI_LIVE_URL=http://localhost:3010 ZAMMAD_KPI_LIVE_TOKEN=... vendor/bin/phpunit --group live
 */
#[Group('live')]
class LiveZammadKpiTest extends TestCase
{
    protected function defineEnvironment($app): void
    {
        parent::defineEnvironment($app);
        $app['config']->set('zammad_kpi.base_url', getenv('ZAMMAD_KPI_LIVE_URL') ?: 'http://localhost:3010');
        $app['config']->set('zammad_kpi.token', getenv('ZAMMAD_KPI_LIVE_TOKEN') ?: '');
        $app['config']->set('zammad_kpi.timeout', 60);
    }

    public function test_every_endpoint_against_real_zammad(): void
    {
        if (! getenv('ZAMMAD_KPI_LIVE_TOKEN')) {
            $this->markTestSkipped('ZAMMAD_KPI_LIVE_TOKEN tidak diisi');
        }
        $kpi = $this->app->make(ZammadKpiClient::class);

        foreach (KpiQuery::ALLOWED_DAYS as $days) {
            $s = $kpi->summary(new KpiQuery($days));
            $this->assertSame($days, $s['window_days']);
            $this->assertCount(5, $s['backlog_aging']);
            $days >= 730 ? $this->assertNull($s['comparison']) : $this->assertNotNull($s['comparison']);
            fwrite(STDERR, sprintf("summary %3d hari: FRT %s (n %d) CSAT %s (n %d) New %d, pembanding %s, grup %d\n",
                $days, var_export($s['frt_median_minutes'], true), $s['frt_count'], var_export($s['csat_average'], true),
                $s['csat_count'], $s['ticket_new'], $s['comparison']['mode'] ?? '-', $s['group_ids_count']));
        }
        foreach (ZammadKpiClient::TREND_METRICS as $metric) {
            $t = $kpi->trend($metric, new KpiQuery(90));
            $this->assertCount(count($t['points']), $t['comparison']['points']);
        }
        $this->assertCount(168, $kpi->heatmap(new KpiQuery(30))['cells']);

        $agents = $kpi->agents(new KpiQuery(90), 3);
        $this->assertNotEmpty($agents['agents']);
        $this->assertArrayHasKey('email', $agents['agents'][0]);
        fwrite(STDERR, 'agents 90 hari: '.$agents['total'].' -- '.json_encode(array_map(fn ($a) => [$a['name'], $a['tickets'], $a['frt_median_minutes']], $agents['agents']))."\n");

        $file = $kpi->export(new KpiQuery(30));
        $this->assertStringStartsWith('PK', $file['content']);
        $zip = tempnam(sys_get_temp_dir(), 'kpi');
        file_put_contents($zip, $file['content']);
        $sheets = (new \ZipArchive)->open($zip) === true ? 'ok' : 'bukan zip';
        fwrite(STDERR, "ekspor {$file['filename']} ".strlen($file['content'])." byte ({$sheets})\n");
        unlink($zip);
    }
}
