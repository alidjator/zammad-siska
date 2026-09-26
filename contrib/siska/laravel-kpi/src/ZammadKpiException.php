<?php

namespace Pkp\SiskaKpi;

use RuntimeException;
use Throwable;

/** Zammad tidak bisa dihubungi / menolak request (token salah = 401/403, filter salah = 422). */
class ZammadKpiException extends RuntimeException
{
    /** @param  int  $status  HTTP status dari Zammad, 0 kalau tidak sampai (timeout / koneksi) */
    public function __construct(string $message, public readonly int $status = 0, ?Throwable $previous = null)
    {
        parent::__construct($message, $status, $previous);
    }
}
