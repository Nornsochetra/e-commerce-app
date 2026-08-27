package com.setec.ecommerce.shared.api;

import com.setec.ecommerce.shared.helper.HeaderContext;
import java.time.Instant;

public record CommonBlock(String requestId, String apiId, Instant timestamp) {
  public static CommonBlock current() {
    return new CommonBlock(HeaderContext.requestId(), HeaderContext.apiId(), Instant.now());
  }
}
