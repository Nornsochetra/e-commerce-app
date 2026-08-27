package com.setec.ecommerce.shared.api;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(ApiStatus status, T data, CommonBlock common, ApiError error) {
  public static <T> ApiResponse<T> success(StatusCode statusCode, T data) {
    return new ApiResponse<>(ApiStatus.of(statusCode), data, CommonBlock.current(), null);
  }

  public static <T> ApiResponse<T> failure(StatusCode statusCode, ApiError error) {
    return new ApiResponse<>(ApiStatus.of(statusCode, error.message()), null, CommonBlock.current(), error);
  }
}
