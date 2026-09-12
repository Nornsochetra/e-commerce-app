package com.setec.ecommerce.notification.payload;

import java.time.Instant;
import java.util.UUID;

public record NotificationResponse(
    UUID id, String type, String title, String message, Instant readAt, Instant createdAt) {}
