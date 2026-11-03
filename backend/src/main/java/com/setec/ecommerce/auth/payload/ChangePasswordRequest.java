package com.setec.ecommerce.auth.payload;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChangePasswordRequest(
    @NotBlank(message = "Current password is required") String currentPassword,
    @NotBlank(message = "New password is required")
        @Size(min = 8, max = 72, message = "Password must contain between 8 and 72 characters")
        String newPassword) {}
