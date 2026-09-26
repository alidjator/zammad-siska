<?php

namespace Pkp\SiskaKpi;

use Illuminate\Contracts\Cache\Factory as CacheFactory;
use Illuminate\Http\Client\Factory as HttpFactory;
use Illuminate\Support\ServiceProvider;

class ZammadKpiServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__.'/../config/zammad_kpi.php', 'zammad_kpi');

        $this->app->singleton(ZammadKpiClient::class, fn ($app) => new ZammadKpiClient(
            $app->make(HttpFactory::class),
            $app['config']->get('zammad_kpi'),
        ));

        $this->app->singleton(KpiService::class, fn ($app) => new KpiService(
            $app->make(ZammadKpiClient::class),
            $app->make(CacheFactory::class)->store($app['config']->get('zammad_kpi.cache_store')),
            $app['config']->get('zammad_kpi'),
        ));
    }

    public function boot(): void
    {
        $this->publishes([__DIR__.'/../config/zammad_kpi.php' => config_path('zammad_kpi.php')], 'zammad-kpi-config');
    }
}
