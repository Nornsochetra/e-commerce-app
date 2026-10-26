import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/notification/app_notification.dart';
import '../../providers/notification/notification_provider.dart';
import '../../providers/order/order_provider.dart';
import '../../providers/product/product_provider.dart';
import '../../theme.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/buttons/circle_icon_button.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/inputs/category_chip.dart';
import '../../widgets/layout/app_header.dart';
import 'widgets/notification_tile.dart';

enum _Filter { all, unread, order, offer, stock }

/// SCR-019 Notifications: Today / Earlier groups, type filters, mark as read, clear all with Undo.
/// Tapping a notification marks it read and opens the order or product it is about.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _Filter _filter = _Filter.all;

  bool _matches(AppNotification n) => switch (_filter) {
        _Filter.all => true,
        _Filter.unread => !n.isRead,
        _Filter.order => n.type == NotificationType.order,
        _Filter.offer => n.type == NotificationType.offer,
        _Filter.stock => n.type == NotificationType.stock,
      };

  /// Opens the order (by its #MC-… reference) or product (by name) mentioned in the message.
  void _open(AppNotification n) {
    context.read<NotificationProvider>().markRead(n.id);
    switch (n.type) {
      case NotificationType.order:
        final reference = RegExp(r'#(MC-\d+)').firstMatch(n.message)?.group(1);
        final orders = context.read<OrderProvider>().orders.where((o) => o.reference == reference);
        context.go(orders.isEmpty ? '/orders' : '/orders/${orders.first.id}');
      case NotificationType.stock:
        final products = context.read<ProductProvider>().products.where((p) => n.message.contains(p.name));
        products.isEmpty ? context.go('/wishlist') : context.push('/product/${products.first.id}');
      case NotificationType.offer:
        context.go('/categories');
    }
  }

  Future<void> _markAll() async {
    await context.read<NotificationProvider>().markAllRead();
    if (mounted) showAppToast(context, 'All caught up');
  }

  Future<void> _clearAll() async {
    final provider = context.read<NotificationProvider>();
    final previous = await provider.clearAll();
    if (mounted) showAppToast(context, 'Notifications cleared', actionLabel: 'Undo', onAction: () => provider.restore(previous));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final items = provider.items;
    final unread = provider.unreadCount;
    final shown = items.where(_matches).toList();
    final now = DateTime.now();
    final today = shown.where((n) => now.difference(n.createdAt) < const Duration(days: 1)).toList();
    final earlier = shown.where((n) => !today.contains(n)).toList();
    int count(NotificationType t) => items.where((n) => n.type == t).length;

    final Widget body;
    if (provider.isLoading && items.isEmpty) {
      body = const ListSkeleton();
    } else if (items.isEmpty) {
      body = EmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications',
        message: 'Order updates, offers and restocks will show up here.',
        actionLabel: 'Explore products',
        onAction: () => context.go('/categories'),
      );
    } else if (shown.isEmpty) {
      final caughtUp = _filter == _Filter.unread;
      body = Column(
        children: [
          EmptyState(
            icon: Icons.done_all_rounded,
            title: caughtUp ? 'You’re all caught up' : 'Nothing here yet',
            message: caughtUp ? 'You’ve read every update. Older ones are under All.' : 'Updates of this type will appear here.',
          ),
          AppButton(label: 'Show all', variant: AppButtonVariant.outline, expanded: false, onPressed: () => setState(() => _filter = _Filter.all)),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (today.isNotEmpty) _Group(title: 'Today', items: today, onOpen: _open, onMarkRead: provider.markRead),
          if (earlier.isNotEmpty) _Group(title: 'Earlier', items: earlier, onOpen: _open, onMarkRead: provider.markRead),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Clear all notifications'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppHeader(
        title: 'Notifications',
        subtitle: unread > 0 ? '$unread unread' : null,
        backFallback: '/home',
        trailing: CircleIconButton(icon: Icons.done_all_rounded, tooltip: 'Mark all as read', onPressed: unread > 0 ? _markAll : null),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          if (items.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final (filter, label, n) in [
                    (_Filter.all, 'All', 0),
                    (_Filter.unread, 'Unread', unread),
                    (_Filter.order, 'Orders', count(NotificationType.order)),
                    (_Filter.offer, 'Offers', count(NotificationType.offer)),
                    (_Filter.stock, 'Stock', count(NotificationType.stock)),
                  ]) ...[
                    CategoryChip(label: label, count: n, selected: _filter == filter, onTap: () => setState(() => _filter = filter)),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          body,
        ],
      ),
    );
  }
}

/// "TODAY" or "EARLIER" label and a card with its notifications.
class _Group extends StatelessWidget {
  final String title;
  final List<AppNotification> items;
  final ValueChanged<AppNotification> onOpen;
  final ValueChanged<String> onMarkRead;

  const _Group({required this.title, required this.items, required this.onOpen, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xxl, AppSpacing.xs, AppSpacing.sm),
          child: Semantics(header: true, child: Text(title.toUpperCase(), style: AppText.meta.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.7))),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.line),
            boxShadow: AppSpacing.shadowSoft,
          ),
          child: Column(
            children: [
              for (final (i, n) in items.indexed) ...[
                if (i > 0) const Divider(height: 1),
                NotificationTile(key: ValueKey(n.id), notification: n, onOpen: () => onOpen(n), onMarkRead: () => onMarkRead(n.id)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
