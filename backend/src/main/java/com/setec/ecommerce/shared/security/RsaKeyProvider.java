package com.setec.ecommerce.shared.security;

import com.setec.ecommerce.shared.properties.JwtProperties;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.env.Environment;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Slf4j
@Getter
@Component
public class RsaKeyProvider {
  private static final String[] EPHEMERAL_KEY_PROFILES = {"dev", "local", "test"};

  private final RSAPublicKey publicKey;
  private final RSAPrivateKey privateKey;

  public RsaKeyProvider(
      JwtProperties properties, ResourceLoader resourceLoader, Environment environment) {
    boolean configured =
        StringUtils.hasText(properties.getPublicKey())
            && StringUtils.hasText(properties.getPrivateKey());
    if (!configured && !environment.matchesProfiles(EPHEMERAL_KEY_PROFILES)) {
      throw new IllegalStateException(
          "No RSA keypair configured. Set RSA_PUBLIC_KEY / RSA_PRIVATE_KEY to `file:` paths "
              + "outside the repo; they are required on every profile except dev/local/test.");
    }

    if (configured) {
      this.publicKey =
          loadPublicKey(
              resourceLoader.getResource(properties.getPublicKey()), properties.getPublicKey());
      this.privateKey =
          loadPrivateKey(
              resourceLoader.getResource(properties.getPrivateKey()), properties.getPrivateKey());
    } else {
      KeyPair pair = generateKeyPair();
      this.publicKey = (RSAPublicKey) pair.getPublic();
      this.privateKey = (RSAPrivateKey) pair.getPrivate();
      log.warn(
          "Using an ephemeral RSA keypair. Tokens expire on restart and cannot be verified by other instances.");
    }
  }

  private RSAPublicKey loadPublicKey(Resource resource, String location) {
    String pem = read(resource, location);
    return (RSAPublicKey)
        generatePublic(new X509EncodedKeySpec(decodePem(pem, location)), location);
  }

  private RSAPrivateKey loadPrivateKey(Resource resource, String location) {
    String pem = read(resource, location);
    if (pem.contains("BEGIN RSA PRIVATE KEY")) {
      throw new IllegalStateException(
          "The private key is PKCS#1, and Java needs PKCS#8. Convert it: openssl pkcs8 "
              + "-topk8 -inform PEM -outform PEM -nocrypt -in keypair.pem -out private-key.pem");
    }
    return (RSAPrivateKey)
        generatePrivate(new PKCS8EncodedKeySpec(decodePem(pem, location)), location);
  }

  private String read(Resource resource, String location) {
    if (!resource.exists()) {
      throw new IllegalStateException("RSA key resource does not exist: " + location);
    }
    try {
      return resource.getContentAsString(StandardCharsets.UTF_8);
    } catch (IOException exception) {
      throw new IllegalStateException("Could not read RSA key resource: " + location, exception);
    }
  }

  private byte[] decodePem(String pem, String location) {
    try {
      String encoded = pem.replaceAll("-----(BEGIN|END)[^-]*-----", "").replaceAll("\\s", "");
      return Base64.getDecoder().decode(encoded);
    } catch (IllegalArgumentException exception) {
      throw new IllegalStateException("RSA key is not valid PEM: " + location, exception);
    }
  }

  private PublicKey generatePublic(X509EncodedKeySpec spec, String location) {
    try {
      return KeyFactory.getInstance("RSA").generatePublic(spec);
    } catch (NoSuchAlgorithmException | InvalidKeySpecException exception) {
      throw new IllegalStateException("Could not load RSA public key: " + location, exception);
    }
  }

  private PrivateKey generatePrivate(PKCS8EncodedKeySpec spec, String location) {
    try {
      return KeyFactory.getInstance("RSA").generatePrivate(spec);
    } catch (NoSuchAlgorithmException | InvalidKeySpecException exception) {
      throw new IllegalStateException("Could not load RSA private key: " + location, exception);
    }
  }

  private KeyPair generateKeyPair() {
    try {
      KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
      generator.initialize(2048);
      return generator.generateKeyPair();
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("RSA algorithm is unavailable", exception);
    }
  }
}
