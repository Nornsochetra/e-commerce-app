package com.setec.ecommerce.order.payload;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record OrderDetailResponse(
    UUID id,
    String reference,
    String status,
    List<OrderItemResponse> items,
    DeliveryResponse delivery,
    String deliveryMethod,
    String estimatedDelivery,
    String paymentMethod,
    MoneyResponse subtotal,
    MoneyResponse deliveryFee,
    MoneyResponse total,
    Instant createdAt,
    Instant updatedAt) {}
