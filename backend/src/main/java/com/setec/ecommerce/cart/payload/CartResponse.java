package com.setec.ecommerce.cart.payload;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record CartResponse(
    UUID id,
    List<CartItemResponse> items,
    MoneyResponse subtotal,
    long itemCount,
    Instant updatedAt) {}
