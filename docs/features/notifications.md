# Notifications

## 1. Overview

Notifications provide an authenticated user with an in-app inbox for order and shopping updates.

## 2. Goals

- Make unread updates visible from the catalog header.
- Let users review all or only unread notifications.
- Let users mark one or all notifications as read.
- Let users clear their notification inbox.

## 3. Actor

- Authenticated user

## 4. Screen

### 4.1 Notifications

- Display unread count in the header.
- Display notifications newest first.
- Support All and Unread filters.
- Visually distinguish unread notifications.
- Support mark-read, mark-all-read, and clear-all actions.
- Display an informative empty state.

## 5. Functional requirements

- NOTIFICATION-FR-001: The catalog header must show a notification indicator when unread items exist.
- NOTIFICATION-FR-002: Selecting the indicator must open the notifications screen.
- NOTIFICATION-FR-003: A user must see only their own notifications.
- NOTIFICATION-FR-004: Notifications must be ordered newest first.
- NOTIFICATION-FR-005: A user must be able to filter the list to unread notifications.
- NOTIFICATION-FR-006: A user must be able to mark one notification as read.
- NOTIFICATION-FR-007: A user must be able to mark all notifications as read.
- NOTIFICATION-FR-008: A user must be able to clear all notifications from their inbox.
- NOTIFICATION-FR-009: The screen must provide loading, empty, loaded, and failure states.

## 6. Business rules

- Notifications require authentication and are owner-scoped.
- V1 types are `order`, `offer`, and `stock`.
- Notification title and message are immutable after creation.
- Reading records `read_at`; an unread notification has `read_at = null`.
- Clearing removes the notification from the user's inbox through soft state; it does not erase the
  server record immediately.
- The unread count includes visible, uncleared notifications only.
- Push notifications, email notifications, preferences, and deep-link actions are deferred.

## 7. UI states

- Loading
- Loaded with unread notifications
- Loaded with all notifications read
- Unread filter with no results
- Empty inbox
- Mark-read operation failure
- Clear-all operation failure

## 8. Dependencies

- Authentication
- Orders for order updates
- Product catalog for stock and offer updates
- Notification API specification

## 9. Acceptance criteria

- The notification indicator opens the inbox.
- Unread count and unread styling agree with notification state.
- Marking one or all as read updates the count immediately.
- Clearing the inbox displays the empty state.
- Refreshing restores the latest server state in production and local mock state in the prototype.
- One user cannot read or mutate another user's notifications.

## 10. Out of scope

- Push delivery
- Email or SMS delivery
- Notification preferences
- Scheduled campaigns
- Deep linking to feature screens
