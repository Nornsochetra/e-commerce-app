package com.setec.ecommerce.shared.api;

import org.springframework.http.ResponseEntity;

public abstract class BaseController {
  protected <T> ResponseEntity<ApiResponse<T>> ok(T data) {
    return ResponseEntity.ok(ApiResponse.success(StatusCode.SUCCESS, data));
  }

  protected <T> ResponseEntity<ApiResponse<T>> created(T data) {
    return ResponseEntity.status(StatusCode.CREATED.getHttpStatus())
        .body(ApiResponse.success(StatusCode.CREATED, data));
  }

  protected <T> ResponseEntity<ApiResponse<T>> accepted(T data) {
    return ResponseEntity.status(StatusCode.ACCEPTED.getHttpStatus())
        .body(ApiResponse.success(StatusCode.ACCEPTED, data));
  }

  protected ResponseEntity<ApiResponse<EmptyJsonResponse>> noContent() {
    return ok(EmptyJsonResponse.INSTANCE);
  }
}
