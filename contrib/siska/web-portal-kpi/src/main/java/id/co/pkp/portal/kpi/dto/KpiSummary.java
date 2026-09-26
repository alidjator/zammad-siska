package id.co.pkp.portal.kpi.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import java.time.OffsetDateTime;
import java.util.List;

/**
 * GET /api/v1/team_kpi. Angka nullable = "belum ada data" di periode itu (tampilkan "—", bukan 0).
 * *State = supergood | good | ok | bad | superbad (null = tanpa data).
 */
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record KpiSummary(
    // Periode (ikut filter days)
    Double frtMedianMinutes,
    Double frtMeanMinutes,
    int frtCount,
    String frtState,
    Double csatAverage,
    int csatCount,
    String csatState,
    Double resolutionMedianMinutes,
    Double resolutionMeanMinutes,
    int resolutionCount,
    int reopenCount,
    int reopenClosedCount,
    Double reopenRatePercent,
    String reopenState,
    List<SlaPriority> slaByPriority,
    // Real-time (tidak ikut filter periode, tidak punya pembanding)
    int ticketNew,
    int ticketOpen,
    int ticketEscalated,
    double escalationRatePercent,
    String escalatedState,
    int eskalasiActive,
    int eskalasiBreached,
    double eskalasiBreachRatePercent,
    String eskalasiBreachState,
    List<BacklogBucket> backlogAging,
    RealtimeComparison realtimeComparison,
    // Konteks
    int windowDays,
    Period period,
    Comparison comparison,
    Integer groupIdsCount,
    OffsetDateTime generatedAt) {

  @JsonIgnoreProperties(ignoreUnknown = true)
  public record Period(OffsetDateTime from, OffsetDateTime to) {}

  /** null kalau tanpa pembanding (periode 2 tahun / melewati batas histori). mode = previous | yoy. */
  @JsonIgnoreProperties(ignoreUnknown = true)
  @JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
  public record Comparison(
      String mode,
      OffsetDateTime from,
      OffsetDateTime to,
      Double frtMedianMinutes,
      Double frtMeanMinutes,
      int frtCount,
      Double csatAverage,
      int csatCount,
      Double resolutionMedianMinutes,
      Double resolutionMeanMinutes,
      int resolutionCount,
      int reopenCount,
      int reopenClosedCount,
      Double reopenRatePercent) {}

  /**
   * Angka real-time ±24 jam lalu dari snapshot per jam (delta "vs kemarin, jam sama").
   * available = false + reason (filters | no_snapshot | no_history) kalau tidak ada.
   */
  @JsonIgnoreProperties(ignoreUnknown = true)
  @JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
  public record RealtimeComparison(
      boolean available,
      String reason,
      OffsetDateTime historySince,
      OffsetDateTime capturedAt,
      Integer ticketNew,
      Integer ticketOpen,
      Integer ticketEscalated,
      Double escalationRatePercent,
      Integer eskalasiActive,
      Integer eskalasiBreached,
      Double eskalasiBreachRatePercent) {}

  /** SLA penyelesaian per prioritas (close_escalation_at). */
  @JsonIgnoreProperties(ignoreUnknown = true)
  @JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
  public record SlaPriority(int priorityId, String priority, int total, int withinSla, Double withinPercent) {}

  /** bucket = lt_1d | d1_3 | d3_7 | d7_30 | gte_30d; toDays null = tanpa batas atas. */
  @JsonIgnoreProperties(ignoreUnknown = true)
  @JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
  public record BacklogBucket(String bucket, int fromDays, Integer toDays, int count) {}
}
