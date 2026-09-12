package com.setec.ecommerce.notification.mapper;

import com.setec.ecommerce.notification.payload.NotificationResponse;
import com.setec.ecommerce.shared.domain.Notification;
import org.springframework.stereotype.Component;

@Component
public class NotificationMapper {
  public NotificationResponse toResponse(Notification notification) {
    return new NotificationResponse(
        notification.getUuid(),
        notification.getType().wireValue(),
        notification.getTitle(),
        notification.getMessage(),
        notification.getReadAt(),
        notification.getCreatedAt());
  }
}
