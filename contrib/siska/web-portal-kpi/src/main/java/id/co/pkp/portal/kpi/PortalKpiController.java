package id.co.pkp.portal.kpi;

import id.co.pkp.portal.kpi.dto.ExportFile;
import id.co.pkp.portal.kpi.dto.KpiHeatmap;
import id.co.pkp.portal.kpi.dto.KpiResult;
import id.co.pkp.portal.kpi.dto.KpiSummary;
import id.co.pkp.portal.kpi.dto.KpiTrend;
import java.util.List;
import java.util.Map;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Endpoint yang dipanggil frontend portal. Token Zammad tetap di server portal -- browser hanya
 * bicara ke endpoint ini. Pasang di balik autentikasi portal yang sudah ada (mis. Spring Security),
 * sama seperti halaman portal lain.
 */
@RestController
@RequestMapping("/api/portal/kpi")
public class PortalKpiController {

  private final KpiService kpi;

  public PortalKpiController(KpiService kpi) {
    this.kpi = kpi;
  }

  @GetMapping("/summary")
  public KpiResult<KpiSummary> summary(
      @RequestParam(defaultValue = "7") int days,
      @RequestParam(required = false) List<Integer> groupIds,
      @RequestParam(required = false) List<Integer> priorityIds,
      @RequestParam(required = false) List<String> channels,
      @RequestParam(required = false) List<String> categories) {
    return kpi.summary(new KpiQuery(days, groupIds, priorityIds, channels, categories, null));
  }

  @GetMapping("/trend")
  public KpiResult<KpiTrend> trend(
      @RequestParam KpiTrend.Metric metric,
      @RequestParam(defaultValue = "7") int days,
      @RequestParam(required = false) List<Integer> groupIds,
      @RequestParam(required = false) List<Integer> priorityIds,
      @RequestParam(required = false) List<String> channels,
      @RequestParam(required = false) List<String> categories) {
    return kpi.trend(metric, new KpiQuery(days, groupIds, priorityIds, channels, categories, null));
  }

  @GetMapping("/heatmap")
  public KpiResult<KpiHeatmap> heatmap(
      @RequestParam(defaultValue = "7") int days,
      @RequestParam(required = false) List<Integer> groupIds,
      @RequestParam(required = false) List<Integer> priorityIds,
      @RequestParam(required = false) List<String> channels,
      @RequestParam(required = false) List<String> categories) {
    return kpi.heatmap(new KpiQuery(days, groupIds, priorityIds, channels, categories, null));
  }

  @GetMapping("/export")
  public ResponseEntity<byte[]> export(
      @RequestParam(defaultValue = "7") int days,
      @RequestParam(required = false) List<Integer> groupIds,
      @RequestParam(required = false) List<Integer> priorityIds,
      @RequestParam(required = false) List<String> channels,
      @RequestParam(required = false) List<String> categories) {
    ExportFile file = kpi.export(new KpiQuery(days, groupIds, priorityIds, channels, categories, null));
    return ResponseEntity.ok()
        .contentType(MediaType.parseMediaType(ExportFile.CONTENT_TYPE))
        .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename(file.filename()).build().toString())
        .body(file.content());
  }

  @ExceptionHandler(IllegalArgumentException.class)
  ResponseEntity<Map<String, String>> badRequest(IllegalArgumentException e) {
    return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
  }

  /** Zammad gagal dan belum ada data terakhir sama sekali (mis. sesaat setelah portal start). */
  @ExceptionHandler(ZammadKpiException.class)
  ResponseEntity<Map<String, String>> upstream(ZammadKpiException e) {
    return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(Map.of("error", "KPI sedang tidak tersedia"));
  }
}
