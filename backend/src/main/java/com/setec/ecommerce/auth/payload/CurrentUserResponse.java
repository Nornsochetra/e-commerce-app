package com.setec.ecommerce.auth.payload;

import java.time.Instant;
import java.util.UUID;

public record CurrentUserResponse(
    UUID id,
    String name,
    String email,
    String phone,
    String role,
    Instant memberSince,
    CurrentUserCountsResponse counts,
    Instant createdAt,
    Instant updatedAt) {}
