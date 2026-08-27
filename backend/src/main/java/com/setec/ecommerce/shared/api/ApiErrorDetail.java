package com.setec.ecommerce.shared.api;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiErrorDetail(String field, String message, Object rejectedValue) {
  public static ApiErrorDetail of(String field, String message) {
    return new ApiErrorDetail(field, message, null);
  }
}
