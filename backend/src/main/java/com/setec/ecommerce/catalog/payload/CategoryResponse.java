package com.setec.ecommerce.catalog.payload;

import java.util.UUID;

public record CategoryResponse(UUID id, String name, String slug) {}
