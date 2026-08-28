package com.setec.ecommerce.catalog.payload;

import java.util.List;
import java.util.UUID;

public record ProductDetailResponse(
    UUID id,
    String name,
    String description,
    CategorySummaryResponse category,
    MoneyResponse price,
    int availableQuantity,
    String rating,
    String imageUrl,
    List<String> badges,
    boolean featured) {}
