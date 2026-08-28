package com.setec.ecommerce.cart.payload;

import java.util.UUID;

public record CartItemResponse(
    UUID id,
    CartProductResponse product,
    int quantity,
    MoneyResponse unitPrice,
    MoneyResponse lineTotal) {}
