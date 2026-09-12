package com.setec.ecommerce.order.payload;

import java.time.Instant;
import java.util.UUID;

public record OrderSummaryResponse(
    UUID id,
    String reference,
    String status,
    long itemCount,
    MoneyResponse total,
    Instant createdAt) {}
