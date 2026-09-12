package com.setec.ecommerce.order.payload;

import java.util.UUID;

public record CheckoutItemResponse(
    UUID productId,
    String name,
    String imageUrl,
    int quantity,
    MoneyResponse unitPrice,
    MoneyResponse lineTotal) {}
