<?php

namespace Pkp\SiskaKpi\Tests;

use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use InvalidArgumentException;
use Pkp\SiskaKpi\KpiQuery;
use Pkp\SiskaKpi\ZammadKpiClient;
use Pkp\SiskaKpi\ZammadKpiException;

class ZammadKpiClientTest extends TestCase
{
    private function client(): ZammadKpiClient
    {
        return $this->app->make(ZammadKpiClient::class);
    }

    public function test_summary_sends_token_and_filters(): void
    {
        Http::fake(['zammad.test/api/v1/team_kpi*' => Http::response(self::summaryJson())]);

        $s = $this->client()->summary(new KpiQuery(90, groupIds: [2, 41], channels: ['email', 'chat'], categories: ['complaint']));

        $this->assertSame(13.1, $s['frt_median_minutes']);
        $this->assertNull($s['csat_average']);
        $this->assertSame('previous', $s['comparison']['mode']);
        Http::assertSent(fn (Request $r) => $r->hasHeader('Authorization', 'Token token=secret-token')
            && $r['days'] == 90 && $r['group_ids'] === '2,41' && $r['channels'] === 'email,chat'
            && $r['categories'] === 'complaint' && ! isset($r['priority_ids']));
    }

    public function test_agents_passes_limit_and_returns_email(): void
    {
        Http::fake(['zammad.test/api/v1/team_kpi/agents*' => Http::response([
            'total' => 23,
            'agents' => [['owner_id' => 50, 'name' => 'Customer Service', 'email' => 'cs@pkp.co.id', 'unassigned' => false, 'tickets' => 1203]],
        ])]);

        $a = $this->client()->agents(KpiQuery::fromArray(['days' => '30']), 10);

        $this->assertSame('cs@pkp.co.id', $a['agents'][0]['email']);
        Http::assertSent(fn (Request $r) => str_contains($r->url(), '/team_kpi/agents') && $r['limit'] == 10 && $r['days'] == 30);
    }

    public function test_trend_rejects_unknown_metric(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->client()->trend('backlog', new KpiQuery);
    }

    public function test_export_keeps_filename(): void
    {
        Http::fake(['zammad.test/api/v1/team_kpi/export*' => Http::response('PK...', 200, [
            'Content-Disposition' => 'attachment; filename="kpi_tim_20260628_20260926.xlsx"; filename*=UTF-8\'\'kpi_tim_20260628_20260926.xlsx',
        ])]);

        $file = $this->client()->export(new KpiQuery(90));

        $this->assertSame('kpi_tim_20260628_20260926.xlsx', $file['filename']);
        $this->assertStringStartsWith('PK', $file['content']);
    }

    public function test_rejected_token_becomes_exception_with_status(): void
    {
        Http::fake(['zammad.test/*' => Http::response(['error' => 'Not authorized'], 403)]);

        try {
            $this->client()->agents(new KpiQuery);
            $this->fail('exception expected');
        } catch (ZammadKpiException $e) {
            $this->assertSame(403, $e->status);
        }
    }

    public function test_query_validates_days_and_parses_request_input(): void
    {
        $q = KpiQuery::fromArray(['days' => '365', 'group_ids' => '2, 41', 'channels' => ['email'], 'compare' => 'yoy']);
        $this->assertSame(['days' => 365, 'group_ids' => '2,41', 'channels' => 'email', 'compare' => 'yoy'], $q->toQuery());

        $this->expectException(InvalidArgumentException::class);
        new KpiQuery(500);
    }
}
