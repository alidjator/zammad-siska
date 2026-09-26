package id.co.pkp.portal.kpi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/**
 * Aplikasi contoh berdiri sendiri. Di Web Portal cukup salin package
 * {@code id.co.pkp.portal.kpi} (tanpa kelas ini) -- lihat docs/INTEGRASI_WEB_PORTAL_KPI.md.
 */
@SpringBootApplication
@ConfigurationPropertiesScan
public class KpiApplication {

  public static void main(String[] args) {
    SpringApplication.run(KpiApplication.class, args);
  }
}
