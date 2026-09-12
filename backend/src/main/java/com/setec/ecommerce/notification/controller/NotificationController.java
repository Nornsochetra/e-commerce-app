package com.setec.ecommerce.notification.controller;

import com.setec.ecommerce.notification.payload.ClearNotificationsResponse;
import com.setec.ecommerce.notification.payload.MarkAllReadResponse;
import com.setec.ecommerce.notification.payload.NotificationResponse;
import com.setec.ecommerce.notification.payload.UnreadCountResponse;
import com.setec.ecommerce.notification.service.NotificationService;
import com.setec.ecommerce.shared.api.ApiId;
import com.setec.ecommerce.shared.api.ApiResponse;
import com.setec.ecommerce.shared.api.BaseController;
import com.setec.ecommerce.shared.api.Pagination;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
@Tag(name = "Notifications")
public class NotificationController extends BaseController {
  private final NotificationService notificationService;

  @GetMapping
  @ApiId("NTF-0101")
  @Operation(summary = "List current user notifications")
  public ResponseEntity<ApiResponse<Pagination<NotificationResponse>>> listNotifications(
      @RequestParam(defaultValue = "0") @Min(value = 0, message = "Page must not be negative")
          int page,
      @RequestParam(defaultValue = "20")
          @Min(value = 1, message = "Size must be at least 1")
          @Max(value = 100, message = "Size must not exceed 100")
          int size,
      @RequestParam(defaultValue = "all")
          @Size(max = 16, message = "Filter must not exceed 16 characters")
          String filter) {
    return ok(notificationService.listNotifications(page, size, filter));
  }

  @GetMapping("/unread-count")
  @ApiId("NTF-0601")
  @Operation(summary = "Read current user unread notification count")
  public ResponseEntity<ApiResponse<UnreadCountResponse>> getUnreadCount() {
    return ok(notificationService.getUnreadCount());
  }

  @PostMapping("/{notificationId}/read")
  @ApiId("NTF-0201")
  @Operation(summary = "Mark one current user notification as read")
  public ResponseEntity<ApiResponse<NotificationResponse>> markRead(
      @PathVariable UUID notificationId) {
    return ok(notificationService.markRead(notificationId));
  }

  @PostMapping("/read-all")
  @ApiId("NTF-0202")
  @Operation(summary = "Mark all current user notifications as read")
  public ResponseEntity<ApiResponse<MarkAllReadResponse>> markAllRead() {
    return ok(notificationService.markAllRead());
  }

  @DeleteMapping
  @ApiId("NTF-0501")
  @Operation(summary = "Clear the current user notification inbox")
  public ResponseEntity<ApiResponse<ClearNotificationsResponse>> clearAll() {
    return ok(notificationService.clearAll());
  }
}
