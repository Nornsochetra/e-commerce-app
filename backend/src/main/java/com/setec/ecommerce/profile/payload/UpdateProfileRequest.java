package com.setec.ecommerce.profile.payload;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UpdateProfileRequest(
    @Pattern(regexp = ".*\\S.*", message = "Name must not be blank")
        @Size(max = 100, message = "Name must not exceed 100 characters")
        String name,
    @Pattern(regexp = ".*\\S.*", message = "Email must not be blank")
        @Email(message = "Email must be valid")
        @Size(max = 255, message = "Email must not exceed 255 characters")
        String email,
    @Size(max = 32, message = "Phone must not exceed 32 characters") String phone) {
  public UpdateProfileRequest {
    name = trim(name);
    email = trim(email);
    phone = trim(phone);
  }

  public boolean hasChanges() {
    return name != null || email != null || phone != null;
  }

  private static String trim(String value) {
    return value == null ? null : value.trim();
  }
}
