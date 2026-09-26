package id.co.pkp.portal.kpi.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import java.util.List;
import java.util.Map;

/** GET /api/v1/team_kpi/heatmap. dow ISO: 1 = Senin .. 7 = Minggu; 168 sel. */
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record KpiHeatmap(
    String timezone,
    int windowDays,
    KpiSummary.Period period,
    Map<Integer, Integer> weekdays,
    double maxAvg,
    List<Cell> cells) {

  @JsonIgnoreProperties(ignoreUnknown = true)
  @JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
  public record Cell(int dow, int hour, int total, double avgPerDay) {}
}
