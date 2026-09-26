<?php

// php artisan vendor:publish --tag=zammad-kpi-config
// Token TIDAK boleh ditulis di file ini -- isi ZAMMAD_KPI_TOKEN di .env / secret store.
return [
    'base_url' => env('ZAMMAD_KPI_BASE_URL', 'https://helpdesk.satu.solutions'),

    // Token akun integrasi-kpi-laravel@pkp.co.id, permission ticket.agent + report
    // (report dibutuhkan untuk agents()). Lihat script/create_kpi_integration_account.rb.
    'token' => env('ZAMMAD_KPI_TOKEN'),

    'connect_timeout' => (int) env('ZAMMAD_KPI_CONNECT_TIMEOUT', 5),   // detik
    'timeout' => (int) env('ZAMMAD_KPI_TIMEOUT', 30),                  // detik; ekspor 2 tahun bisa beberapa detik

    // Berapa lama hasil dianggap segar -- samakan dengan auto-refresh dashboard (5 menit).
    'cache_ttl' => (int) env('ZAMMAD_KPI_CACHE_TTL', 300),              // detik
    // Kalau Zammad gagal, data terakhir masih boleh ditampilkan selama ini (ditandai stale).
    'stale_max_age' => (int) env('ZAMMAD_KPI_STALE_MAX_AGE', 86400),    // detik

    // null = cache store default aplikasi.
    'cache_store' => env('ZAMMAD_KPI_CACHE_STORE'),
];
