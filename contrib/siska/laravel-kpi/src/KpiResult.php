<?php

namespace Pkp\SiskaKpi;

use DateTimeImmutable;
use JsonSerializable;

/**
 * Data + status kesegarannya, supaya UI bisa menampilkan "Gagal memuat -- angka terakhir pukul
 * HH:MM" (artboard kondisi data di mockup) tanpa mengosongkan dashboard.
 */
final class KpiResult implements JsonSerializable
{
    public function __construct(
        public readonly array $data,
        /** true = Zammad sedang gagal, ini data terakhir yang berhasil diambil */
        public readonly bool $stale,
        public readonly DateTimeImmutable $fetchedAt,
        public readonly ?string $error = null,
    ) {}

    public function jsonSerialize(): array
    {
        return [
            'data' => $this->data,
            'stale' => $this->stale,
            'fetched_at' => $this->fetchedAt->format(DATE_ATOM),
            'error' => $this->error,
        ];
    }
}
