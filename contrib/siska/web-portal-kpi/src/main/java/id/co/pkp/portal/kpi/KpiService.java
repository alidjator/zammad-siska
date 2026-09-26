package id.co.pkp.portal.kpi;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import id.co.pkp.portal.kpi.dto.ExportFile;
import id.co.pkp.portal.kpi.dto.KpiHeatmap;
import id.co.pkp.portal.kpi.dto.KpiResult;
import id.co.pkp.portal.kpi.dto.KpiSummary;
import id.co.pkp.portal.kpi.dto.KpiTrend;
import java.time.Clock;
import java.time.Instant;
import java.util.function.Supplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * KPI untuk portal: cache supaya semua staf yang membuka portal tidak masing-masing memicu query
 * ke Zammad (ringkasan 2 tahun ±2 detik), dan fallback ke data terakhir kalau Zammad gagal.
 *
 * <p>Dua lapis per query: "segar" (TTL = cacheTtl, default 5 menit) dan "terakhir berhasil"
 * (maks staleMaxAge, default 24 jam). Karena angkanya sama untuk semua staf, kuncinya cukup
 * parameter query -- tidak per user.
 */
@Service
public class KpiService {

  private static final Logger log = LoggerFactory.getLogger(KpiService.class);

  private final ZammadKpiClient client;
  private final Clock clock;
  private final Cache<String, KpiResult<?>> fresh;
  private final Cache<String, KpiResult<?>> lastGood;

  @Autowired
  public KpiService(ZammadKpiClient client, ZammadKpiProperties props) {
    this(client, props, Clock.systemUTC());
  }

  KpiService(ZammadKpiClient client, ZammadKpiProperties props, Clock clock) {
    this.client = client;
    this.clock = clock;
    this.fresh = Caffeine.newBuilder().expireAfterWrite(props.cacheTtl()).maximumSize(500).build();
    this.lastGood = Caffeine.newBuilder().expireAfterWrite(props.staleMaxAge()).maximumSize(500).build();
  }

  public KpiResult<KpiSummary> summary(KpiQuery query) {
    return cached("summary|" + query.cacheKey(), () -> client.summary(query));
  }

  public KpiResult<KpiTrend> trend(KpiTrend.Metric metric, KpiQuery query) {
    return cached("trend|" + metric + "|" + query.cacheKey(), () -> client.trend(metric, query));
  }

  public KpiResult<KpiHeatmap> heatmap(KpiQuery query) {
    return cached("heatmap|" + query.cacheKey(), () -> client.heatmap(query));
  }

  /** Ekspor tidak di-cache: file harus mencerminkan kondisi saat diunduh. */
  public ExportFile export(KpiQuery query) {
    return client.export(query);
  }

  @SuppressWarnings("unchecked")
  private <T> KpiResult<T> cached(String key, Supplier<T> load) {
    KpiResult<T> hit = (KpiResult<T>) fresh.getIfPresent(key);
    if (hit != null) {
      return hit;
    }
    try {
      KpiResult<T> result = new KpiResult<>(load.get(), false, Instant.now(clock), null);
      fresh.put(key, result);
      lastGood.put(key, result);
      return result;
    } catch (ZammadKpiException e) {
      KpiResult<T> previous = (KpiResult<T>) lastGood.getIfPresent(key);
      if (previous == null) {
        throw e;
      }
      log.warn("{} -- menampilkan data terakhir dari {}", e.getMessage(), previous.fetchedAt());
      return new KpiResult<>(previous.data(), true, previous.fetchedAt(), e.getMessage());
    }
  }
}
