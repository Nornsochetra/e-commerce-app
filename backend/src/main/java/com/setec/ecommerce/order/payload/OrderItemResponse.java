package com.setec.ecommerce.order.payload;

import java.util.UUID;

public record OrderItemResponse(
    UUID productId, String name, int quantity, MoneyResponse unitPrice, MoneyResponse lineTotal) {}
