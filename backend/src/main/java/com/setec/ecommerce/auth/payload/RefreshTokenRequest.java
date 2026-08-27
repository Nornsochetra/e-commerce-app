package com.setec.ecommerce.auth.payload;

import jakarta.validation.constraints.NotBlank;

public record RefreshTokenRequest(
    @NotBlank(message = "Refresh token is required") String refreshToken) {}
