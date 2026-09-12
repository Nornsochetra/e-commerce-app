package com.setec.ecommerce.notification.service;

import com.setec.ecommerce.notification.mapper.NotificationMapper;
import com.setec.ecommerce.notification.payload.ClearNotificationsResponse;
import com.setec.ecommerce.notification.payload.MarkAllReadResponse;
import com.setec.ecommerce.notification.payload.NotificationResponse;
import com.setec.ecommerce.notification.payload.UnreadCountResponse;
import com.setec.ecommerce.shared.api.Pagination;
import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.domain.Notification;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.exception.BusinessException;
import com.setec.ecommerce.shared.helper.CurrentUserResolver;
import com.setec.ecommerce.shared.repository.NotificationRepository;
import java.time.Instant;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NotificationService {
  private static final String FILTER_ALL = "all";
  private static final String FILTER_UNREAD = "unread";
  private static final Sort NEWEST_FIRST =
      Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"));

  private final CurrentUserResolver currentUserResolver;
  private final NotificationRepository notificationRepository;
  private final NotificationMapper notificationMapper;

  @Transactional(readOnly = true)
  public Pagination<NotificationResponse> listNotifications(
      int page, int size, String filterValue) {
    User user = currentUserResolver.require();
    String filter = requireValidFilter(filterValue);
    PageRequest pageable = PageRequest.of(page, size, NEWEST_FIRST);
    Page<Notification> notifications =
        FILTER_UNREAD.equals(filter)
            ? notificationRepository.findPageByUserIdAndReadAtIsNullAndClearedAtIsNull(
                user.getId(), pageable)
            : notificationRepository.findPageByUserIdAndClearedAtIsNull(user.getId(), pageable);
    return Pagination.of(notifications, notificationMapper::toResponse);
  }

  @Transactional(readOnly = true)
  public UnreadCountResponse getUnreadCount() {
    User user = currentUserResolver.require();
    return new UnreadCountResponse(unreadCount(user.getId()));
  }

  @Transactional
  public NotificationResponse markRead(UUID notificationId) {
    User user = currentUserResolver.require();
    Notification notification =
        notificationRepository
            .findByUserIdAndUuidAndClearedAtIsNull(user.getId(), notificationId)
            .orElseThrow(() -> new BusinessException(StatusCode.NOTIFICATION_NOT_FOUND));
    if (notification.getReadAt() == null) {
      notification.setReadAt(Instant.now());
    }
    return notificationMapper.toResponse(notification);
  }

  @Transactional
  public MarkAllReadResponse markAllRead() {
    User user = currentUserResolver.require();
    int updatedCount = notificationRepository.markAllVisibleRead(user.getId(), Instant.now());
    return new MarkAllReadResponse(updatedCount, unreadCount(user.getId()));
  }

  @Transactional
  public ClearNotificationsResponse clearAll() {
    User user = currentUserResolver.require();
    int clearedCount = notificationRepository.clearAllVisible(user.getId(), Instant.now());
    return new ClearNotificationsResponse(clearedCount, unreadCount(user.getId()));
  }

  private long unreadCount(Long userId) {
    return notificationRepository.countByUserIdAndReadAtIsNullAndClearedAtIsNull(userId);
  }

  private String requireValidFilter(String filter) {
    if (FILTER_ALL.equals(filter) || FILTER_UNREAD.equals(filter)) {
      return filter;
    }
    throw new BusinessException(StatusCode.VALIDATION_ERROR);
  }
}
