package com.setec.ecommerce.shared.exception;

import com.setec.ecommerce.shared.api.ApiError;
import com.setec.ecommerce.shared.api.ApiErrorDetail;
import com.setec.ecommerce.shared.api.ApiResponse;
import com.setec.ecommerce.shared.api.StatusCode;
import jakarta.validation.ConstraintViolationException;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.env.Environment;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpMediaTypeNotAcceptableException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import tools.jackson.databind.exc.InvalidFormatException;

@Slf4j
@RestControllerAdvice
@RequiredArgsConstructor
public class GlobalExceptionHandler {
  private final Environment environment;

  @ExceptionHandler(BusinessException.class)
  ResponseEntity<ApiResponse<Void>> handleBusiness(BusinessException exception) {
    log.warn("Business error: {}", exception.getMessage());
    return respond(exception.getStatusCode(), exception.getMessage(), null);
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException exception) {
    List<ApiErrorDetail> details =
        exception.getBindingResult().getFieldErrors().stream().map(this::toDetail).toList();
    return respond(StatusCode.VALIDATION_ERROR, StatusCode.VALIDATION_ERROR.getMessage(), details);
  }

  @ExceptionHandler(MethodArgumentTypeMismatchException.class)
  ResponseEntity<ApiResponse<Void>> handleTypeMismatch(
      MethodArgumentTypeMismatchException exception) {
    return respond(
        StatusCode.INVALID_REQUEST,
        "Invalid value for " + exception.getName(),
        List.of(
            new ApiErrorDetail(
                exception.getName(),
                "Value has the wrong type",
                safeValue(exception.getName(), exception.getValue()))));
  }

  @ExceptionHandler(MissingRequestHeaderException.class)
  ResponseEntity<ApiResponse<Void>> handleMissingHeader(MissingRequestHeaderException exception) {
    return respond(StatusCode.INVALID_REQUEST, exception.getMessage(), null);
  }

  @ExceptionHandler(HttpMessageNotReadableException.class)
  ResponseEntity<ApiResponse<Void>> handleUnreadable(HttpMessageNotReadableException exception) {
    if (exception.getCause() instanceof InvalidFormatException cause
        && cause.getTargetType().isEnum()
        && !cause.getPath().isEmpty()) {
      String field = cause.getPath().get(cause.getPath().size() - 1).getPropertyName();
      String accepted =
          String.join(
              ", ",
              Arrays.stream(cause.getTargetType().getEnumConstants())
                  .map(String::valueOf)
                  .toList());
      String message =
          "'" + cause.getValue() + "' is not a valid " + field + ". Accepted values: " + accepted;
      return respond(
          StatusCode.INVALID_REQUEST,
          message,
          List.of(new ApiErrorDetail(field, message, safeValue(field, cause.getValue()))));
    }
    return respond(StatusCode.INVALID_REQUEST, "Request body could not be read", null);
  }

  @ExceptionHandler(AccessDeniedException.class)
  ResponseEntity<ApiResponse<Void>> handleAccessDenied(AccessDeniedException exception) {
    return respond(StatusCode.FORBIDDEN, StatusCode.FORBIDDEN.getMessage(), null);
  }

  @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
  ResponseEntity<ApiResponse<Void>> handleMethod(HttpRequestMethodNotSupportedException exception) {
    return respond(StatusCode.METHOD_NOT_ALLOWED, exception.getMessage(), null);
  }

  @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
  ResponseEntity<ApiResponse<Void>> handleUnsupportedMedia(
      HttpMediaTypeNotSupportedException exception) {
    return respond(StatusCode.UNSUPPORTED_MEDIA_TYPE, exception.getMessage(), null);
  }

  @ExceptionHandler(HttpMediaTypeNotAcceptableException.class)
  ResponseEntity<ApiResponse<Void>> handleNotAcceptable(
      HttpMediaTypeNotAcceptableException exception) {
    return respond(StatusCode.NOT_ACCEPTABLE, exception.getMessage(), null);
  }

  @ExceptionHandler(MissingServletRequestParameterException.class)
  ResponseEntity<ApiResponse<Void>> handleMissingParameter(
      MissingServletRequestParameterException exception) {
    return respond(StatusCode.INVALID_REQUEST, exception.getMessage(), null);
  }

  @ExceptionHandler(NoResourceFoundException.class)
  ResponseEntity<ApiResponse<Void>> handleNotFound(NoResourceFoundException exception) {
    return respond(
        StatusCode.NOT_FOUND, StatusCode.NOT_FOUND.format(exception.getResourcePath()), null);
  }

  @ExceptionHandler(ConstraintViolationException.class)
  ResponseEntity<ApiResponse<Void>> handleConstraint(ConstraintViolationException exception) {
    List<ApiErrorDetail> details =
        exception.getConstraintViolations().stream()
            .map(
                violation -> {
                  String field = violation.getPropertyPath().toString();
                  return new ApiErrorDetail(
                      field, violation.getMessage(), safeValue(field, violation.getInvalidValue()));
                })
            .toList();
    return respond(StatusCode.VALIDATION_ERROR, StatusCode.VALIDATION_ERROR.getMessage(), details);
  }

  @ExceptionHandler(HandlerMethodValidationException.class)
  ResponseEntity<ApiResponse<Void>> handleMethodValidation(
      HandlerMethodValidationException exception) {
    return respond(StatusCode.VALIDATION_ERROR, exception.getMessage(), null);
  }

  @ExceptionHandler(MaxUploadSizeExceededException.class)
  ResponseEntity<ApiResponse<Void>> handleMaxUpload(MaxUploadSizeExceededException exception) {
    return respond(StatusCode.PAYLOAD_TOO_LARGE, StatusCode.PAYLOAD_TOO_LARGE.getMessage(), null);
  }

  @ExceptionHandler(DataIntegrityViolationException.class)
  ResponseEntity<ApiResponse<Void>> handleDataIntegrity(DataIntegrityViolationException exception) {
    log.error("Database constraint violation", exception);
    return respond(StatusCode.CONFLICT, StatusCode.CONFLICT.getMessage(), null);
  }

  @ExceptionHandler(ObjectOptimisticLockingFailureException.class)
  ResponseEntity<ApiResponse<Void>> handleOptimisticLock(
      ObjectOptimisticLockingFailureException exception) {
    log.warn("Optimistic locking conflict", exception);
    return respond(StatusCode.CONFLICT, StatusCode.CONFLICT.getMessage(), null);
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<ApiResponse<Void>> handleUnexpected(Exception exception) {
    log.error("Unhandled error", exception);
    String message =
        environment.matchesProfiles("dev", "local", "test")
            ? exception.getMessage()
            : StatusCode.INTERNAL_ERROR.getMessage();
    return respond(StatusCode.INTERNAL_ERROR, message, null);
  }

  private ApiErrorDetail toDetail(FieldError error) {
    return new ApiErrorDetail(
        error.getField(),
        error.getDefaultMessage(),
        safeValue(error.getField(), error.getRejectedValue()));
  }

  private Object safeValue(String field, Object value) {
    String normalized = field.toLowerCase(Locale.ROOT);
    boolean sensitive =
        normalized.contains("password")
            || normalized.contains("secret")
            || normalized.contains("token");
    return sensitive ? null : value;
  }

  private ResponseEntity<ApiResponse<Void>> respond(
      StatusCode code, String message, List<ApiErrorDetail> details) {
    return ResponseEntity.status(code.getHttpStatus())
        .body(ApiResponse.failure(code, ApiError.of(code, message, details)));
  }
}
