<?php

namespace Pkp\SiskaKpi\Tests;

use Illuminate\Support\Facades\Http;
use Pkp\SiskaKpi\KpiQuery;
use Pkp\SiskaKpi\KpiService;
use Pkp\SiskaKpi\ZammadKpiException;

class KpiServiceTest extends TestCase
{
    public function test_same_query_is_served_from_cache(): void
    {
        Http::fake(['zammad.test/*' => Http::response(self::summaryJson())]);
        $kpi = $this->app->make(KpiService::class);

        $first = $kpi->summary(new KpiQuery(90));
        $second = $kpi->summary(new KpiQuery(90));

        Http::assertSentCount(1);
        $this->assertFalse($second->stale);
        $this->assertEquals($first->fetchedAt, $second->fetchedAt);
    }

    public function test_when_zammad_fails_last_good_data_is_returned_as_stale(): void
    {
        $this->app['config']->set('zammad_kpi.cache_ttl', 0); // tanpa cache segar
        Http::fakeSequence('zammad.test/*')->push(self::summaryJson())->push('boom', 500);
        $kpi = $this->app->make(KpiService::class);

        $ok = $kpi->summary(new KpiQuery(90));
        $fallback = $kpi->summary(new KpiQuery(90));

        $this->assertTrue($fallback->stale);
        $this->assertSame(140, $fallback->data['ticket_new']);
        $this->assertEquals($ok->fetchedAt, $fallback->fetchedAt);
        $this->assertStringContainsString('HTTP 500', $fallback->error);
        $this->assertSame(true, $fallback->jsonSerialize()['stale']);
    }

    public function test_without_previous_data_the_error_is_raised(): void
    {
        Http::fake(['zammad.test/*' => Http::response('boom', 500)]);

        $this->expectException(ZammadKpiException::class);
        $this->app->make(KpiService::class)->summary(new KpiQuery);
    }
}
