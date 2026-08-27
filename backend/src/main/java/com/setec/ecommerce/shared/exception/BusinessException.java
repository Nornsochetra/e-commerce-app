package com.setec.ecommerce.shared.exception;

import com.setec.ecommerce.shared.api.StatusCode;
import lombok.Getter;

@Getter
public class BusinessException extends RuntimeException {
  private final transient StatusCode statusCode;

  public BusinessException(StatusCode statusCode, Object... args) {
    super(statusCode.format(args));
    this.statusCode = statusCode;
  }
}
