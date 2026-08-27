package com.setec.ecommerce.shared.security;

import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.exception.BusinessException;
import com.setec.ecommerce.shared.properties.JwtProperties;
import java.time.Duration;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.stereotype.Component;

@Component
public class JwtTokenProvider {
  private final JwtProperties properties;
  private final JwtEncoder encoder;
  private final NimbusJwtDecoder decoder;

  public JwtTokenProvider(RsaKeyProvider keys, JwtProperties properties) {
    this.properties = properties;
    RSAKey jwk =
        new RSAKey.Builder(keys.getPublicKey()).privateKey(keys.getPrivateKey()).build();
    this.encoder = new NimbusJwtEncoder(new ImmutableJWKSet<>(new JWKSet(jwk)));
    this.decoder = NimbusJwtDecoder.withPublicKey(keys.getPublicKey()).build();
    this.decoder.setJwtValidator(JwtValidators.createDefaultWithIssuer(properties.getIssuer()));
  }

  public String generate(String subject, TokenType tokenType, Collection<String> roles) {
    Instant issuedAt = Instant.now();
    Duration ttl =
        tokenType == TokenType.ACCESS
            ? properties.getAccessTokenTtl()
            : properties.getRefreshTokenTtl();
    JwtClaimsSet claims =
        JwtClaimsSet.builder()
            .issuer(properties.getIssuer())
            .issuedAt(issuedAt)
            .expiresAt(issuedAt.plus(ttl))
            .subject(subject)
            .claim(TokenType.CLAIM, tokenType.name())
            .claim("roles", List.copyOf(roles))
            .build();
    JwsHeader header = JwsHeader.with(SignatureAlgorithm.RS256).build();
    return encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
  }

  public JwtClaims parse(String token) {
    try {
      var jwt = decoder.decode(token);
      return new JwtClaims(
          jwt.getSubject(),
          TokenType.valueOf(jwt.getClaimAsString(TokenType.CLAIM)),
          List.copyOf(jwt.getClaimAsStringList("roles")),
          jwt.getExpiresAt());
    } catch (JwtException | IllegalArgumentException | NullPointerException exception) {
      throw new BusinessException(StatusCode.INVALID_TOKEN);
    }
  }
}
