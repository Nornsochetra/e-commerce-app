import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification/notification_provider.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/layout/app_header.dart';

/// PLACEHOLDER (slice 1). Filters, groups, mark-as-read and clear come in slice 5.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppHeader(title: 'Notifications', subtitle: notifications.unreadCount == 0 ? null : '${notifications.unreadCount} unread', backFallback: '/home'),
      body: Center(
        child: EmptyState(
          icon: Icons.notifications_none_rounded,
          title: '${notifications.items.length} notifications',
          message: 'The notification list is built in slice 5.',
          actionLabel: notifications.unreadCount > 0 ? 'Mark all as read' : null,
          onAction: notifications.markAllRead,
        ),
      ),
    );
  }
}
