package id.co.pkp.portal.kpi;

import jakarta.validation.constraints.NotBlank;
import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;
import org.springframework.validation.annotation.Validated;

/**
 * Koneksi ke API KPI Tim Zammad ({@code zammad.kpi.*}).
 *
 * @param baseUrl      URL Zammad, mis. https://helpdesk.satu.solutions
 * @param token        token API akun integrasi (integration-kpi-api@pkp.co.id), permission ticket.agent
 * @param cacheTtl     berapa lama hasil dianggap segar (samakan dengan auto-refresh dashboard, 5 menit)
 * @param staleMaxAge  kalau Zammad gagal, data terakhir masih boleh ditampilkan selama ini
 */
@Validated
@ConfigurationProperties("zammad.kpi")
public record ZammadKpiProperties(
    @NotBlank String baseUrl,
    @NotBlank String token,
    @DefaultValue("5s") Duration connectTimeout,
    @DefaultValue("30s") Duration readTimeout,
    @DefaultValue("5m") Duration cacheTtl,
    @DefaultValue("24h") Duration staleMaxAge) {}
