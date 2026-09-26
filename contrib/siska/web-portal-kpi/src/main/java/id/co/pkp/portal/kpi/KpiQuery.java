package id.co.pkp.portal.kpi;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.web.util.UriBuilder;

/**
 * Parameter yang sama untuk semua endpoint KPI (lihat docs/DESIGN_TEAM_KPI_DASHBOARD.md 10.1-10.2).
 * Kosong/null = tanpa filter. Angka yang dihasilkan selalu dalam scope grup akun integrasi.
 */
public record KpiQuery(
    int days,
    List<Integer> groupIds,
    List<Integer> priorityIds,
    List<String> channels,
    List<String> categories,
    String compare) {

  /** Pilihan periode di dashboard; 730 = batas histori production (tanpa pembanding). */
  public static final Set<Integer> ALLOWED_DAYS = Set.of(7, 30, 90, 180, 365, 730);
  public static final Set<String> COMPARE_MODES = Set.of("auto", "previous", "yoy", "none");

  public KpiQuery {
    if (!ALLOWED_DAYS.contains(days)) {
      throw new IllegalArgumentException("days harus salah satu dari " + ALLOWED_DAYS);
    }
    if (compare != null && !COMPARE_MODES.contains(compare)) {
      throw new IllegalArgumentException("compare harus salah satu dari " + COMPARE_MODES);
    }
    groupIds = groupIds == null ? List.of() : List.copyOf(groupIds);
    priorityIds = priorityIds == null ? List.of() : List.copyOf(priorityIds);
    channels = channels == null ? List.of() : List.copyOf(channels);
    categories = categories == null ? List.of() : List.copyOf(categories);
  }

  public static KpiQuery ofDays(int days) {
    return new KpiQuery(days, null, null, null, null, null);
  }

  UriBuilder apply(UriBuilder uri) {
    uri.queryParam("days", days);
    addList(uri, "group_ids", groupIds);
    addList(uri, "priority_ids", priorityIds);
    addList(uri, "channels", channels);
    addList(uri, "categories", categories);
    if (compare != null) {
      uri.queryParam("compare", compare);
    }
    return uri;
  }

  /** Kunci cache: query yang sama = hasil yang sama. */
  String cacheKey() {
    return days + "|" + groupIds + "|" + priorityIds + "|" + channels + "|" + categories + "|" + compare;
  }

  private static void addList(UriBuilder uri, String name, List<?> values) {
    if (!values.isEmpty()) {
      uri.queryParam(name, values.stream().map(String::valueOf).collect(Collectors.joining(",")));
    }
  }
}
