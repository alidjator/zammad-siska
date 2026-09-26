<?php

namespace Pkp\SiskaKpi\Tests;

use Orchestra\Testbench\TestCase as Orchestra;
use Pkp\SiskaKpi\ZammadKpiServiceProvider;

abstract class TestCase extends Orchestra
{
    protected function getPackageProviders($app): array
    {
        return [ZammadKpiServiceProvider::class];
    }

    protected function defineEnvironment($app): void
    {
        $app['config']->set('cache.default', 'array');
        $app['config']->set('zammad_kpi.base_url', 'https://zammad.test');
        $app['config']->set('zammad_kpi.token', 'secret-token');
    }

    /** Dipangkas dari respons asli staging /api/v1/team_kpi?days=90 (akun integrasi). */
    public static function summaryJson(): array
    {
        return [
            'frt_median_minutes' => 13.1, 'frt_mean_minutes' => 707.9, 'frt_count' => 1359, 'frt_state' => 'supergood',
            'csat_average' => null, 'csat_count' => 0, 'csat_state' => null,
            'resolution_median_minutes' => 195.7, 'resolution_count' => 6309,
            'reopen_rate_percent' => 4.3, 'reopen_state' => 'supergood',
            'sla_by_priority' => [['priority_id' => 2, 'priority' => '2 normal', 'total' => 5098, 'within_sla' => 4828, 'within_percent' => 94.7]],
            'ticket_new' => 140, 'ticket_open' => 79, 'ticket_escalated' => 169,
            'backlog_aging' => [['bucket' => 'lt_1d', 'from_days' => 0, 'to_days' => 1, 'count' => 12]],
            'window_days' => 90,
            'comparison' => ['mode' => 'previous', 'frt_median_minutes' => 24.6, 'frt_count' => 2091],
            'group_ids_count' => 34,
        ];
    }
}
