package id.co.pkp.portal.kpi;

import static org.assertj.core.api.Assertions.assertThat;

import id.co.pkp.portal.kpi.dto.KpiTrend;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.web.client.RestClient;

/**
 * Uji ke Zammad sungguhan. Hanya jalan kalau env diisi:
 * ZAMMAD_KPI_LIVE_URL=http://localhost:3010 ZAMMAD_KPI_LIVE_TOKEN=... mvn test
 */
@EnabledIfEnvironmentVariable(named = "ZAMMAD_KPI_LIVE_TOKEN", matches = ".+")
class LiveZammadKpiIT {

  ZammadKpiClient client() {
    var props = new ZammadKpiProperties(System.getenv("ZAMMAD_KPI_LIVE_URL"), System.getenv("ZAMMAD_KPI_LIVE_TOKEN"),
        Duration.ofSeconds(5), Duration.ofSeconds(60), Duration.ofMinutes(5), Duration.ofHours(24));
    return new ZammadKpiClient(ZammadKpiConfig.configure(RestClient.builder(), props).build());
  }

  @Test
  void everyEndpointParsesAgainstRealZammad() {
    var kpi = client();

    for (int days : KpiQuery.ALLOWED_DAYS) {
      var s = kpi.summary(KpiQuery.ofDays(days));
      assertThat(s.windowDays()).isEqualTo(days);
      assertThat(s.backlogAging()).hasSize(5);
      if (days >= 730) {
        assertThat(s.comparison()).isNull();
      } else {
        assertThat(s.comparison()).isNotNull();
      }
      System.out.printf("summary %3d hari: FRT %s (n %d) CSAT %s (n %d) New %d Open %d Escalated %d, pembanding %s, grup %s%n",
          days, s.frtMedianMinutes(), s.frtCount(), s.csatAverage(), s.csatCount(), s.ticketNew(), s.ticketOpen(),
          s.ticketEscalated(), s.comparison() == null ? "-" : s.comparison().mode(), s.groupIdsCount());
    }
    for (KpiTrend.Metric m : KpiTrend.Metric.values()) {
      var t = kpi.trend(m, KpiQuery.ofDays(90));
      assertThat(t.points()).isNotEmpty();
      assertThat(t.comparison().points()).hasSameSizeAs(t.points());
      System.out.printf("trend %s 90 hari: %d %s%n", m, t.points().size(), t.bucket());
    }
    var h = kpi.heatmap(KpiQuery.ofDays(30));
    assertThat(h.cells()).hasSize(168);
    var file = kpi.export(KpiQuery.ofDays(30));
    assertThat(file.filename()).startsWith("kpi_tim_").endsWith(".xlsx");
    assertThat(file.content()).startsWith((byte) 'P', (byte) 'K');
    System.out.printf("heatmap max %.1f/hari, ekspor %s %d byte%n", h.maxAvg(), file.filename(), file.content().length);
  }
}
