package com.setec.ecommerce.shared.logging;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class LogMaskConverterTest {
  @Test
  void masksJsonSecretsIncludingPrefixedKeys() {
    String message = "{\"password\":\"hunter2\",\"accessToken\":\"eyJabc\",\"x-api-key\":\"key\"}";

    assertThat(LogMaskConverter.mask(message))
        .isEqualTo("{\"password\":\"***\",\"accessToken\":\"***\",\"x-api-key\":\"***\"}");
  }

  @Test
  void masksFormTokenWithoutConsumingFollowingField() {
    assertThat(LogMaskConverter.mask("refresh_token=eyJabc&next=1"))
        .isEqualTo("refresh_token=***&next=1");
  }

  @Test
  void leavesOrdinaryMessagesByteIdentical() {
    String message = "request completed with status 200";
    assertThat(LogMaskConverter.mask(message)).isSameAs(message);
  }
}
