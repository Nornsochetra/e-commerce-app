package com.setec.ecommerce.auth.payload;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LoginRequest(
    @NotBlank(message = "Email is required")
        @Email(message = "Email must be valid")
        @Size(max = 255, message = "Email must not exceed 255 characters")
        String email,
    @NotBlank(message = "Password is required")
        @Size(min = 8, max = 72, message = "Password must contain between 8 and 72 characters")
        String password) {
  public LoginRequest {
    email = email == null ? null : email.trim();
  }
}
