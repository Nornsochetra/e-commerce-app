package com.setec.ecommerce.notification.payload;

public record ClearNotificationsResponse(int clearedCount, long unreadCount) {}
