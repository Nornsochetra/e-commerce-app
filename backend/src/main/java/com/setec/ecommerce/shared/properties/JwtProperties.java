package com.setec.ecommerce.shared.properties;

import java.time.Duration;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "app.jwt")
public class JwtProperties {
  private String issuer;
  private Duration accessTokenTtl;
  private Duration refreshTokenTtl;
  private String publicKey;
  private String privateKey;
}
