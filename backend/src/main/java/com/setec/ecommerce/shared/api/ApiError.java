package com.setec.ecommerce.shared.api;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiError(String code, ErrorType type, String message, List<ApiErrorDetail> details) {
  public static ApiError of(StatusCode statusCode, String message) {
    return of(statusCode, message, null);
  }

  public static ApiError of(StatusCode statusCode, String message, List<ApiErrorDetail> details) {
    List<ApiErrorDetail> normalizedDetails =
        details == null || details.isEmpty() ? null : List.copyOf(details);
    return new ApiError(
        statusCode.getCode(), statusCode.getErrorType(), message, normalizedDetails);
  }
}
