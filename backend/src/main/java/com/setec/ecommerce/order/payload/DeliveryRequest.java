package com.setec.ecommerce.order.payload;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.Locale;

public record DeliveryRequest(
    @NotBlank(message = "Recipient name is required")
        @Size(max = 120, message = "Recipient name must not exceed 120 characters")
        String recipientName,
    @NotBlank(message = "Delivery email is required")
        @Email(message = "Delivery email must be valid")
        @Size(max = 255, message = "Delivery email must not exceed 255 characters")
        String email,
    @NotBlank(message = "Delivery address is required")
        @Size(max = 1000, message = "Delivery address must not exceed 1000 characters")
        String address) {
  public DeliveryRequest {
    recipientName = trim(recipientName);
    email = email == null ? null : email.trim().toLowerCase(Locale.ROOT);
    address = trim(address);
  }

  private static String trim(String value) {
    return value == null ? null : value.trim();
  }
}
