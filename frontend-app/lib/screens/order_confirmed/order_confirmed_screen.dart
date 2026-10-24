import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/order/order_provider.dart';
import '../../theme.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/empty_state.dart';

/// PLACEHOLDER (slice 1). The full confirmation (animated check, delivery window) comes in slice 4.
class OrderConfirmedScreen extends StatelessWidget {
  final String orderId;
  const OrderConfirmedScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(orderId);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EmptyState(
                icon: Icons.check_rounded,
                title: 'Order confirmed!',
                message: order == null ? 'We couldn’t find that order.' : 'Order #${order.reference} has been placed.',
              ),
              if (order != null) AppButton(label: 'Track order', onPressed: () => context.go('/orders/${order.id}')),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: 'Continue shopping', variant: AppButtonVariant.outline, onPressed: () => context.go('/home')),
            ],
          ),
        ),
      ),
    );
  }
}
