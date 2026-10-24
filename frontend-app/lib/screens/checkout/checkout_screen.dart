import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/cart/cart_provider.dart';
import '../../providers/notification/notification_provider.dart';
import '../../providers/order/order_provider.dart';
import '../../providers/user/user_provider.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/layout/action_dock.dart';
import '../../widgets/layout/app_header.dart';

/// PLACEHOLDER (slice 1): places an order with the saved profile so the order flow can be tested.
/// The full checkout (address edit, payment choice, review) comes in slice 4.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  Future<void> _placeOrder(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final user = context.read<UserProvider>().user;
    final order = await context.read<OrderProvider>().placeOrder(
          items: cart.items,
          recipientName: user?.name ?? 'Customer',
          email: user?.email ?? '',
          address: '12 Riverside Street, Phnom Penh',
        );
    if (order == null || !context.mounted) return;
    await cart.clear();
    if (!context.mounted) return;
    context.read<NotificationProvider>().load(); // the new "Order confirmed" notification
    context.go('/orders/${order.id}/confirmed');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final placing = context.watch<OrderProvider>().isPlacing;
    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: const AppHeader(title: 'Checkout', backFallback: '/cart'),
        body: Center(child: EmptyState(icon: Icons.shopping_bag_outlined, title: 'Your cart is empty', message: 'Add products to your cart before checking out.', actionLabel: 'Browse products', onAction: () => context.go('/categories'))),
      );
    }
    return Scaffold(
      appBar: const AppHeader(title: 'Checkout', backFallback: '/cart'),
      body: const Center(child: EmptyState(icon: Icons.construction_rounded, title: 'Checkout', message: 'The full checkout form is built in slice 4. Place order below uses your saved profile.')),
      bottomNavigationBar: ActionDock(children: [
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total', style: AppText.meta),
          Text(formatMoney(cart.total), style: AppText.price.copyWith(fontSize: 18)),
        ]),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: AppButton(label: 'Place order', isLoading: placing, onPressed: () => _placeOrder(context))),
      ]),
    );
  }
}
