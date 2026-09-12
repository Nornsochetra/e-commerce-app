package com.setec.ecommerce.order.payload;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CheckoutRequest(
    @NotNull(message = "Delivery information is required") @Valid DeliveryRequest delivery,
    @NotBlank(message = "Delivery method is required")
        @Size(max = 24, message = "Delivery method must not exceed 24 characters")
        String deliveryMethod,
    @NotBlank(message = "Payment method is required")
        @Size(max = 32, message = "Payment method must not exceed 32 characters")
        String paymentMethod) {
  public CheckoutRequest {
    deliveryMethod = trim(deliveryMethod);
    paymentMethod = trim(paymentMethod);
  }

  private static String trim(String value) {
    return value == null ? null : value.trim();
  }
}
