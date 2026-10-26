import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/order/order.dart';
import '../../providers/order/order_provider.dart';
import '../../theme.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/inputs/category_chip.dart';
import '../../widgets/layout/app_header.dart';
import 'widgets/order_card.dart';

enum _Filter { all, active, delivered }

/// SCR-017 Order history with All / In progress / Delivered filters. Reached from Profile.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  _Filter _filter = _Filter.all;

  bool _matches(Order o) => switch (_filter) {
        _Filter.all => true,
        _Filter.active => o.isActive,
        _Filter.delivered => !o.isActive,
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.orders;
    final active = orders.where((o) => o.isActive).length;
    final shown = orders.where(_matches).toList();

    final Widget body;
    if (provider.isLoading && orders.isEmpty) {
      body = const ListSkeleton(count: 2);
    } else if (provider.error != null && orders.isEmpty) {
      body = EmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load your orders', message: 'Check your connection and try again.', actionLabel: 'Try again', onAction: provider.load);
    } else if (orders.isEmpty) {
      body = EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No orders yet',
        message: 'Orders you place will appear here so you can track them.',
        actionLabel: 'Start shopping',
        onAction: () => context.go('/categories'),
      );
    } else if (shown.isEmpty) {
      body = Column(
        children: [
          EmptyState(icon: Icons.inventory_2_outlined, title: 'Nothing here', message: _filter == _Filter.active ? 'You have no orders in progress.' : 'No delivered orders yet.'),
          AppButton(label: 'Show all orders', variant: AppButtonVariant.outline, expanded: false, onPressed: () => setState(() => _filter = _Filter.all)),
        ],
      );
    } else {
      body = Column(
        children: [
          for (final o in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: OrderCard(order: o, onTap: () => context.push('/orders/${o.id}')),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: const AppHeader(title: 'My Orders', backFallback: '/profile'),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
          children: [
            if (orders.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    for (final (filter, label, count) in [
                      (_Filter.all, 'All', orders.length),
                      (_Filter.active, 'In progress', active),
                      (_Filter.delivered, 'Delivered', orders.length - active),
                    ]) ...[
                      CategoryChip(label: label, count: count, selected: _filter == filter, onTap: () => setState(() => _filter = filter)),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            body,
          ],
        ),
      ),
    );
  }
}
