package com.setec.ecommerce.auth.payload;

import java.util.UUID;

public record UserIdentityResponse(UUID id, String name, String email, String phone, String role) {}
