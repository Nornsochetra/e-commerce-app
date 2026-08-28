package com.setec.ecommerce.shared.api;

import java.text.MessageFormat;
import java.util.Arrays;
import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public enum StatusCode {
  SUCCESS(HttpStatus.OK, ErrorType.NONE, "Success"),
  CREATED(HttpStatus.CREATED, ErrorType.NONE, "Created"),
  ACCEPTED(HttpStatus.ACCEPTED, ErrorType.NONE, "Accepted"),
  INVALID_REQUEST(HttpStatus.BAD_REQUEST, ErrorType.VALIDATION, "Invalid request"),
  VALIDATION_ERROR(HttpStatus.BAD_REQUEST, ErrorType.VALIDATION, "Validation failed"),
  UNAUTHORIZED(HttpStatus.UNAUTHORIZED, ErrorType.AUTHENTICATION, "Authentication is required"),
  INVALID_TOKEN(HttpStatus.UNAUTHORIZED, ErrorType.AUTHENTICATION, "Token is invalid or expired"),
  FORBIDDEN(HttpStatus.FORBIDDEN, ErrorType.AUTHORIZATION, "Access is forbidden"),
  NOT_FOUND(HttpStatus.NOT_FOUND, ErrorType.NOT_FOUND, "The resource {0} was not found"),
  METHOD_NOT_ALLOWED(
      HttpStatus.METHOD_NOT_ALLOWED, ErrorType.VALIDATION, "HTTP method is not allowed"),
  NOT_ACCEPTABLE(
      HttpStatus.NOT_ACCEPTABLE, ErrorType.VALIDATION, "Response type is not acceptable"),
  DUPLICATE(HttpStatus.CONFLICT, ErrorType.CONFLICT, "The resource already exists"),
  CONFLICT(HttpStatus.CONFLICT, ErrorType.CONFLICT, "The request conflicts with current state"),
  PAYLOAD_TOO_LARGE(
      HttpStatus.CONTENT_TOO_LARGE, ErrorType.VALIDATION, "Request payload is too large"),
  UNSUPPORTED_MEDIA_TYPE(
      HttpStatus.UNSUPPORTED_MEDIA_TYPE, ErrorType.VALIDATION, "Media type is not supported"),
  INTERNAL_ERROR(
      HttpStatus.INTERNAL_SERVER_ERROR, ErrorType.SYSTEM, "An unexpected error occurred"),
  INVALID_CREDENTIALS(
      HttpStatus.UNAUTHORIZED, ErrorType.AUTHENTICATION, "Email or password is incorrect"),
  ACCOUNT_DISABLED(HttpStatus.UNAUTHORIZED, ErrorType.AUTHENTICATION, "Account is disabled"),
  EMAIL_ALREADY_REGISTERED(HttpStatus.CONFLICT, ErrorType.CONFLICT, "Email is already registered"),
  INVALID_REFRESH_TOKEN(
      HttpStatus.UNAUTHORIZED, ErrorType.AUTHENTICATION, "Refresh token is invalid"),
  USER_NOT_FOUND(HttpStatus.NOT_FOUND, ErrorType.NOT_FOUND, "User was not found"),
  CATEGORY_NOT_FOUND(HttpStatus.NOT_FOUND, ErrorType.NOT_FOUND, "Category was not found"),
  PRODUCT_NOT_FOUND(HttpStatus.NOT_FOUND, ErrorType.NOT_FOUND, "Product was not found"),
  CART_ITEM_NOT_FOUND(HttpStatus.NOT_FOUND, ErrorType.NOT_FOUND, "Cart item was not found"),
  PRODUCT_OUT_OF_STOCK(HttpStatus.CONFLICT, ErrorType.CONFLICT, "Product is out of stock"),
  INSUFFICIENT_STOCK(
      HttpStatus.CONFLICT, ErrorType.CONFLICT, "Requested quantity exceeds available stock");

  private final HttpStatus httpStatus;
  private final ErrorType errorType;
  private final String message;

  StatusCode(HttpStatus httpStatus, ErrorType errorType, String message) {
    this.httpStatus = httpStatus;
    this.errorType = errorType;
    this.message = message;
  }

  public String getCode() {
    return name();
  }

  public String format(Object... args) {
    if (args.length == 0) {
      return message;
    }
    Object[] asText = Arrays.stream(args).map(String::valueOf).toArray();
    return MessageFormat.format(message, asText);
  }
}
