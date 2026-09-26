package id.co.pkp.portal.kpi;

import id.co.pkp.portal.kpi.dto.ExportFile;
import id.co.pkp.portal.kpi.dto.KpiHeatmap;
import id.co.pkp.portal.kpi.dto.KpiSummary;
import id.co.pkp.portal.kpi.dto.KpiTrend;
import java.util.function.Supplier;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

/**
 * Panggilan mentah ke API KPI Tim Zammad (tanpa cache). Dipakai lewat {@link KpiService}.
 * Endpoint /team_kpi/agents sengaja tidak ada: portal menampilkan angka tim yang sama untuk semua
 * staf, dan token integrasi (permission ticket.agent) memang tidak punya akses ke sana.
 */
@Component
public class ZammadKpiClient {

  private final RestClient http;

  public ZammadKpiClient(RestClient zammadKpiRestClient) {
    this.http = zammadKpiRestClient;
  }

  public KpiSummary summary(KpiQuery query) {
    return call("summary", () -> http.get()
        .uri(uri -> query.apply(uri.path("/api/v1/team_kpi")).build())
        .retrieve()
        .body(KpiSummary.class));
  }

  public KpiTrend trend(KpiTrend.Metric metric, KpiQuery query) {
    return call("trend " + metric, () -> http.get()
        .uri(uri -> query.apply(uri.path("/api/v1/team_kpi/trend").queryParam("metric", metric.name())).build())
        .retrieve()
        .body(KpiTrend.class));
  }

  public KpiHeatmap heatmap(KpiQuery query) {
    return call("heatmap", () -> http.get()
        .uri(uri -> query.apply(uri.path("/api/v1/team_kpi/heatmap")).build())
        .retrieve()
        .body(KpiHeatmap.class));
  }

  public ExportFile export(KpiQuery query) {
    return call("export", () -> {
      ResponseEntity<byte[]> response = http.get()
          .uri(uri -> query.apply(uri.path("/api/v1/team_kpi/export")).build())
          .retrieve()
          .toEntity(byte[].class);
      String disposition = response.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION);
      String filename = disposition == null ? null : ContentDisposition.parse(disposition).getFilename();
      return new ExportFile(filename != null ? filename : "kpi_tim.xlsx", response.getBody());
    });
  }

  private <T> T call(String what, Supplier<T> request) {
    try {
      return request.get();
    } catch (RestClientResponseException e) {
      throw new ZammadKpiException(
          "Zammad KPI " + what + " gagal: HTTP " + e.getStatusCode().value(), e.getStatusCode().value(), e);
    } catch (ResourceAccessException e) {
      throw new ZammadKpiException("Zammad KPI " + what + " tidak bisa dihubungi: " + e.getMessage(), 0, e);
    }
  }
}
