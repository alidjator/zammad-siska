package id.co.pkp.portal.kpi.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import java.time.LocalDate;
import java.util.List;

/**
 * GET /api/v1/team_kpi/trend. bucket = day | week | month (zona waktu {@code timezone}).
 * comparison.points sejajar per indeks dengan points; comparison null = tanpa pembanding.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record KpiTrend(
    String metric,
    String bucket,
    String timezone,
    int windowDays,
    KpiSummary.Period period,
    List<Point> points,
    Comparison comparison,
    /** hanya metric escalated: snapshot tertua (null = belum ada snapshot) */
    java.time.OffsetDateTime historySince,
    /** hanya metric escalated: "filters" kalau tidak tersedia dengan filter aktif */
    String unavailable) {

  /** value null = tidak ada data di bucket itu (volume selalu angka, 0 = tidak ada tiket). */
  @JsonIgnoreProperties(ignoreUnknown = true)
  @JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
  public record Point(LocalDate bucketStart, Double value, int count) {}

  @JsonIgnoreProperties(ignoreUnknown = true)
  public record Comparison(String mode, KpiSummary.Period period, List<Point> points) {}

  /**
   * Metrik yang tersedia. escalated = Rasio Escalated (%) dari snapshot per jam: riwayatnya baru
   * ada sejak job snapshot berjalan (historySince), dan tidak tersedia (unavailable = "filters")
   * kalau filter prioritas/channel/kategori dipakai.
   */
  public enum Metric { frt, csat, volume, resolution, escalated }
}
