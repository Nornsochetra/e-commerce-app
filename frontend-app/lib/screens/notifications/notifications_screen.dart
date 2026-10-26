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
import '../../widgets/feedback/confirm_dialog.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/inputs/category_chip.dart';
import '../../widgets/layout/app_header.dart';
import '../../utils/on_screen.dart';
import 'widgets/notification_tile.dart';

enum _Filter { all, unread, order, offer, stock }

/// SCR-019 Notifications from the server: Today / Earlier groups, type filters, mark as read, clear all
/// (asks first: the server can't undo it).
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
        // References look like MC-1A2B3C4D5E6F.
        final reference = RegExp(r'#(MC-[A-Z0-9]+)').firstMatch(n.message)?.group(1);
        final order = reference == null ? null : context.read<OrderProvider>().summaryByReference(reference);
        context.go(order == null ? '/orders' : '/orders/${order.id}');
      case NotificationType.stock:
        final product = context.read<ProductProvider>().productMentionedIn(n.message);
        product == null ? context.go('/wishlist') : context.push('/product/${product.id}');
      case NotificationType.offer:
        context.go('/categories');
    }
  }

  Future<void> _markAll() async {
    final error = await context.read<NotificationProvider>().markAllRead();
    if (mounted) showAppToast(context, error ?? 'All caught up');
  }

  /// The server can't bring cleared notifications back, so this asks first (there is no Undo).
  Future<void> _clearAll() async {
    final provider = context.read<NotificationProvider>();
    final ok = await showConfirmDialog(context, title: 'Clear all notifications?', message: 'They’ll be removed from your inbox. This can’t be undone.', confirmLabel: 'Clear all', danger: true);
    if (!ok || !mounted) return;
    final error = await provider.clearAll();
    if (mounted) showAppToast(context, error ?? 'Notifications cleared');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    loadWhenOnScreen(context, provider.ensureLoaded);
    final items = provider.items;
    final unread = provider.unreadCount;
    final shown = items.where(_matches).toList();
    final now = DateTime.now();
    final today = shown.where((n) => now.difference(n.createdAt) < const Duration(days: 1)).toList();
    final earlier = shown.where((n) => !today.contains(n)).toList();
    int count(NotificationType t) => items.where((n) => n.type == t).length;

    final Widget body;
    if ((provider.isLoading || !provider.isLoaded) && items.isEmpty) {
      body = const ListSkeleton();
    } else if (provider.error != null && items.isEmpty) {
      body = EmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load notifications', message: provider.error!, actionLabel: 'Try again', onAction: provider.load);
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
      // Loads older notifications when the list is scrolled close to its end.
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) provider.loadMore();
          return false;
        },
        child: ListView(
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
                    ]) ...[CategoryChip(label: label, count: n, selected: _filter == filter, onTap: () => setState(() => _filter = filter)), const SizedBox(width: AppSpacing.sm)],
                  ],
                ),
              ),
            body,
            if (provider.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
              ),
          ],
        ),
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
          child: Semantics(
            header: true,
            child: Text(title.toUpperCase(), style: AppText.meta.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.7)),
          ),
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
