package id.co.pkp.portal.kpi;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
public class ZammadKpiConfig {

  @Bean
  RestClient zammadKpiRestClient(RestClient.Builder builder, ZammadKpiProperties props) {
    return configure(builder, props).build();
  }

  /**
   * Base URL + header token + timeout dari properties. Memakai API Spring Framework (bukan helper
   * Spring Boot yang berganti nama di Boot 3.4/4.0) supaya bisa disalin apa adanya ke portal
   * Boot 3.2+ maupun 4.x. Terpisah dari @Bean supaya test bisa memasang MockRestServiceServer
   * setelahnya.
   */
  static RestClient.Builder configure(RestClient.Builder builder, ZammadKpiProperties props) {
    var factory = new SimpleClientHttpRequestFactory();
    factory.setConnectTimeout(props.connectTimeout());
    factory.setReadTimeout(props.readTimeout());
    return builder
        .baseUrl(props.baseUrl())
        .defaultHeader(HttpHeaders.AUTHORIZATION, "Token token=" + props.token())
        .requestFactory(factory);
  }
}
