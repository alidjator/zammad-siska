package id.co.pkp.portal.kpi.dto;

import java.time.Instant;

/**
 * Data + status kesegarannya, supaya UI portal bisa menampilkan kondisi "Gagal memuat -- angka
 * terakhir pukul HH:MM" (lihat artboard kondisi data di mockup) tanpa mengosongkan dashboard.
 *
 * @param stale     true = Zammad sedang gagal, ini data terakhir yang berhasil diambil
 * @param fetchedAt kapan data ini diambil dari Zammad
 * @param error     pesan singkat kalau stale
 */
public record KpiResult<T>(T data, boolean stale, Instant fetchedAt, String error) {}
