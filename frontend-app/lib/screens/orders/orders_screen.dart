import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/order/order.dart';
import '../../providers/order/order_provider.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/feedback/status_badge.dart';
import '../../widgets/layout/app_header.dart';

/// Badge colour for each order status (shared idea with the order detail screen).
BadgeTone orderStatusTone(OrderStatus status) => switch (status) {
      OrderStatus.pending => BadgeTone.warning,
      OrderStatus.confirmed || OrderStatus.shipped => BadgeTone.info,
      OrderStatus.delivered => BadgeTone.success,
    };

/// PLACEHOLDER (slice 1): simple order list. Filters and order cards come in slice 4.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    return Scaffold(
      appBar: const AppHeader(title: 'My Orders', backFallback: '/profile'),
      body: orders.isLoading
          ? const Padding(padding: EdgeInsets.all(AppSpacing.page), child: ListSkeleton(count: 2))
          : orders.orders.isEmpty
              ? Center(child: EmptyState(icon: Icons.inventory_2_outlined, title: 'No orders yet', message: 'Orders you place will appear here.', actionLabel: 'Start shopping', onAction: () => context.go('/categories')))
              : ListView(
                  padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
                  children: [
                    for (final o in orders.orders)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Order #${o.reference}', style: AppText.head),
                        subtitle: Text('${formatDate(o.createdAt)} · ${o.itemCount} items · ${formatMoney(o.total)}', style: AppText.meta),
                        trailing: StatusBadge(label: formatLabel(o.status.name), tone: orderStatusTone(o.status)),
                        onTap: () => context.push('/orders/${o.id}'),
                      ),
                  ],
                ),
    );
  }
}
