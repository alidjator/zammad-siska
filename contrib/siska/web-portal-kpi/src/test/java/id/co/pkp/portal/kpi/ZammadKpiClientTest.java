package id.co.pkp.portal.kpi;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import id.co.pkp.portal.kpi.dto.KpiSummary;
import id.co.pkp.portal.kpi.dto.KpiTrend;
import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class ZammadKpiClientTest {

  static final String BASE = "https://zammad.test";

  /** Dipangkas dari respons asli staging /api/v1/team_kpi?days=7. */
  static final String SUMMARY_JSON = """
      {"frt_median_minutes":0.3,"frt_mean_minutes":1.2,"frt_count":63,"frt_state":"supergood",
       "csat_average":3.98,"csat_count":49,"csat_state":"ok",
       "resolution_median_minutes":null,"resolution_mean_minutes":null,"resolution_count":0,
       "reopen_count":0,"reopen_closed_count":3,"reopen_rate_percent":0.0,"reopen_state":"supergood",
       "sla_by_priority":[{"priority_id":2,"priority":"2 normal","total":5098,"within_sla":4828,"within_percent":94.7}],
       "ticket_new":140,"ticket_open":79,"ticket_escalated":169,"escalation_rate_percent":77.2,"escalated_state":"bad",
       "eskalasi_active":3,"eskalasi_breached":3,"eskalasi_breach_rate_percent":100.0,"eskalasi_breach_state":"superbad",
       "backlog_aging":[{"bucket":"lt_1d","from_days":0,"to_days":1,"count":12},{"bucket":"gte_30d","from_days":30,"to_days":null,"count":138}],
       "window_days":7,"period":{"from":"2026-09-19T15:26:57Z","to":"2026-09-26T15:26:57Z"},
       "comparison":{"from":"2026-09-12T15:26:57Z","to":"2026-09-19T15:26:57Z","mode":"previous","frt_median_minutes":0.0,
         "frt_mean_minutes":220.1,"frt_count":43,"csat_average":null,"csat_count":0,"resolution_median_minutes":null,
         "resolution_mean_minutes":null,"resolution_count":0,"reopen_count":0,"reopen_closed_count":0,"reopen_rate_percent":null},
       "filters":{"group_ids":[],"priority_ids":[],"channels":[],"categories":[]},"group_ids_count":34,
       "generated_at":"2026-09-26T15:26:58Z","some_future_field":123}
      """;

  MockRestServiceServer server;
  ZammadKpiClient client;

  @BeforeEach
  void setUp() {
    var props = new ZammadKpiProperties(BASE, "secret-token", Duration.ofSeconds(1), Duration.ofSeconds(1), Duration.ofMinutes(5), Duration.ofHours(24));
    RestClient.Builder builder = ZammadKpiConfig.configure(RestClient.builder(), props);
    server = MockRestServiceServer.bindTo(builder).build();
    client = new ZammadKpiClient(builder.build());
  }

  @Test
  void summarySendsTokenAndFiltersAndParsesSnakeCase() {
    server.expect(requestTo(BASE + "/api/v1/team_kpi?days=30&group_ids=2,41&channels=email,chat&categories=complaint"))
        .andExpect(header(HttpHeaders.AUTHORIZATION, "Token token=secret-token"))
        .andRespond(withSuccess(SUMMARY_JSON, MediaType.APPLICATION_JSON));

    KpiSummary s = client.summary(new KpiQuery(30, List.of(2, 41), null, List.of("email", "chat"), List.of("complaint"), null));

    assertThat(s.frtMedianMinutes()).isEqualTo(0.3);
    assertThat(s.frtCount()).isEqualTo(63);
    assertThat(s.csatState()).isEqualTo("ok");
    assertThat(s.resolutionMedianMinutes()).isNull();
    assertThat(s.ticketNew()).isEqualTo(140);
    assertThat(s.slaByPriority()).singleElement().satisfies(p -> assertThat(p.withinPercent()).isEqualTo(94.7));
    assertThat(s.backlogAging()).extracting(KpiSummary.BacklogBucket::toDays).containsExactly(1, null);
    assertThat(s.comparison().mode()).isEqualTo("previous");
    assertThat(s.comparison().csatAverage()).isNull();
    assertThat(s.groupIdsCount()).isEqualTo(34);
    server.verify();
  }

  @Test
  void comparisonIsNullForTwoYears() {
    server.expect(requestTo(BASE + "/api/v1/team_kpi?days=730"))
        .andRespond(withSuccess(SUMMARY_JSON.replaceFirst("\"comparison\":\\{[^}]*\\}", "\"comparison\":null"), MediaType.APPLICATION_JSON));

    assertThat(client.summary(KpiQuery.ofDays(730)).comparison()).isNull();
  }

  @Test
  void trendParsesPointsAndNullValues() {
    server.expect(requestTo(BASE + "/api/v1/team_kpi/trend?metric=csat&days=7"))
        .andRespond(withSuccess("""
            {"metric":"csat","bucket":"day","timezone":"Asia/Jakarta","window_days":7,
             "period":{"from":"2026-09-19T15:26:57Z","to":"2026-09-26T15:26:57Z"},
             "points":[{"bucket_start":"2026-09-19","value":null,"count":0},{"bucket_start":"2026-09-20","value":4.0,"count":3}],
             "comparison":{"mode":"previous","period":{"from":"2026-09-12T15:26:57Z","to":"2026-09-19T15:26:57Z"},
               "points":[{"bucket_start":"2026-09-12","value":3.5,"count":2},{"bucket_start":"2026-09-13","value":null,"count":0}]}}
            """, MediaType.APPLICATION_JSON));

    KpiTrend t = client.trend(KpiTrend.Metric.csat, KpiQuery.ofDays(7));

    assertThat(t.points()).extracting(KpiTrend.Point::value).containsExactly(null, 4.0);
    assertThat(t.comparison().points()).hasSameSizeAs(t.points());
  }

  @Test
  void exportKeepsFilenameFromZammad() {
    server.expect(requestTo(BASE + "/api/v1/team_kpi/export?days=90"))
        .andRespond(withSuccess(new byte[] {'P', 'K'}, MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"kpi_tim_20260628_20260926.xlsx\""));

    var file = client.export(KpiQuery.ofDays(90));

    assertThat(file.filename()).isEqualTo("kpi_tim_20260628_20260926.xlsx");
    assertThat(file.content()).startsWith((byte) 'P', (byte) 'K');
  }

  @Test
  void rejectedTokenBecomesZammadKpiException() {
    server.expect(requestTo(BASE + "/api/v1/team_kpi?days=7")).andRespond(withStatus(HttpStatus.UNAUTHORIZED));

    assertThatThrownBy(() -> client.summary(KpiQuery.ofDays(7)))
        .isInstanceOf(ZammadKpiException.class)
        .satisfies(e -> assertThat(((ZammadKpiException) e).status()).isEqualTo(401));
  }

  @Test
  void queryRejectsDaysOutsideDashboardOptions() {
    assertThatThrownBy(() -> KpiQuery.ofDays(500)).isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> new KpiQuery(7, null, null, null, null, "tomorrow")).isInstanceOf(IllegalArgumentException.class);
  }
}
