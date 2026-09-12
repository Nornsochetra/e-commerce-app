package com.setec.ecommerce.order.payload;

import java.time.Instant;
import java.util.List;

public record CheckoutPreviewResponse(
    List<CheckoutItemResponse> items,
    String deliveryMethod,
    String estimatedDelivery,
    MoneyResponse subtotal,
    MoneyResponse deliveryFee,
    MoneyResponse total,
    Instant expiresAt) {}
