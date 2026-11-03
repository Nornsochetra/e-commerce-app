package com.setec.ecommerce.shared.security;

import static org.assertj.core.api.Assertions.assertThat;

import com.setec.ecommerce.shared.properties.JwtProperties;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.core.io.DefaultResourceLoader;
import org.springframework.mock.env.MockEnvironment;

class RsaKeyProviderTest {
  @TempDir Path keyDir;

  @Test
  void devKeypairIsSavedOnceAndReusedSoTokensSurviveARestart() {
    RsaKeyProvider first = provider(keyDir.toString());
    RsaKeyProvider afterRestart = provider(keyDir.toString());

    assertThat(keyDir.resolve("public-key.pem")).exists();
    assertThat(keyDir.resolve("private-key.pem")).exists();
    assertThat(afterRestart.getPublicKey()).isEqualTo(first.getPublicKey());
    assertThat(afterRestart.getPrivateKey()).isEqualTo(first.getPrivateKey());
  }

  @Test
  void withoutAKeyFolderEachStartGetsAThrowawayKeypair() {
    assertThat(provider(null).getPublicKey()).isNotEqualTo(provider(null).getPublicKey());
    assertThat(keyDir).isEmptyDirectory();
  }

  private RsaKeyProvider provider(String devKeyDir) {
    JwtProperties properties = new JwtProperties();
    properties.setDevKeyDir(devKeyDir);
    MockEnvironment environment = new MockEnvironment();
    environment.setActiveProfiles("dev");
    return new RsaKeyProvider(properties, new DefaultResourceLoader(), environment);
  }
}
