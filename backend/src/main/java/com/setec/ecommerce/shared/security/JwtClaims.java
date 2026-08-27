package com.setec.ecommerce.shared.security;

import java.time.Instant;
import java.util.List;

public record JwtClaims(
    String subject,
    TokenType tokenType,
    List<String> roles,
    long tokenVersion,
    Instant expiresAt) {}
