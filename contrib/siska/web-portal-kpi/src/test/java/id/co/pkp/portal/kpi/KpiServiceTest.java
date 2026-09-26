package id.co.pkp.portal.kpi;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.ExpectedCount.once;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class KpiServiceTest {

  static final String BASE = "https://zammad.test";
  static final String URL = BASE + "/api/v1/team_kpi?days=7";

  MockRestServiceServer server;

  KpiService service(Duration cacheTtl) {
    var props = new ZammadKpiProperties(BASE, "t", Duration.ofSeconds(1), Duration.ofSeconds(1), cacheTtl, Duration.ofHours(24));
    RestClient.Builder builder = ZammadKpiConfig.configure(RestClient.builder(), props);
    server = MockRestServiceServer.bindTo(builder).build();
    return new KpiService(new ZammadKpiClient(builder.build()), props);
  }

  @Test
  void sameQueryIsServedFromCacheForEveryone() {
    KpiService kpi = service(Duration.ofMinutes(5));
    server.expect(once(), requestTo(URL)).andRespond(withSuccess(ZammadKpiClientTest.SUMMARY_JSON, MediaType.APPLICATION_JSON));

    var first = kpi.summary(KpiQuery.ofDays(7));
    var second = kpi.summary(KpiQuery.ofDays(7));

    assertThat(second).isSameAs(first);
    assertThat(second.stale()).isFalse();
    server.verify(); // hanya satu request ke Zammad
  }

  @Test
  void whenZammadFailsTheLastGoodDataIsReturnedAsStale() {
    KpiService kpi = service(Duration.ZERO); // tanpa cache segar: setiap panggilan ke Zammad
    server.expect(requestTo(URL)).andRespond(withSuccess(ZammadKpiClientTest.SUMMARY_JSON, MediaType.APPLICATION_JSON));
    server.expect(requestTo(URL)).andRespond(withServerError());

    var ok = kpi.summary(KpiQuery.ofDays(7));
    var fallback = kpi.summary(KpiQuery.ofDays(7));

    assertThat(fallback.stale()).isTrue();
    assertThat(fallback.data().ticketNew()).isEqualTo(140);
    assertThat(fallback.fetchedAt()).isEqualTo(ok.fetchedAt());
    assertThat(fallback.error()).contains("HTTP 500");
  }

  @Test
  void withoutAnyPreviousDataTheErrorIsRaised() {
    KpiService kpi = service(Duration.ofMinutes(5));
    server.expect(requestTo(URL)).andRespond(withServerError());

    assertThatThrownBy(() -> kpi.summary(KpiQuery.ofDays(7))).isInstanceOf(ZammadKpiException.class);
  }
}
