package com.setec.ecommerce.auth.payload;

public record TokenResponse(String accessToken, String refreshToken, long expiresIn) {}
