package com.setec.ecommerce.auth.payload;

public record AuthResponse(
    String accessToken, String refreshToken, long expiresIn, UserIdentityResponse user) {}
