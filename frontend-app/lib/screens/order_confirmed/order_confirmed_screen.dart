import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/order/order.dart';
import '../../providers/order/order_provider.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/buttons/circle_icon_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/layout/app_header.dart';

/// SCR-016 Order confirmation, shown full screen after Place order (/orders/:id/confirmed).
class OrderConfirmedScreen extends StatelessWidget {
  final String orderId;
  const OrderConfirmedScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(orderId);
    if (order == null) {
      return Scaffold(
        appBar: const AppHeader(title: 'Order', backFallback: '/orders'),
        body: ListView(children: [
          EmptyState(icon: Icons.inventory_2_outlined, title: 'Order not found', message: 'We couldn’t find that order.', actionLabel: 'View my orders', onAction: () => context.go('/orders')),
        ]),
      );
    }

    final firstName = order.recipientName.trim().split(' ').first;
    return Scaffold(
      appBar: AppHeader(
        showBack: false,
        trailing: CircleIconButton(icon: Icons.close_rounded, tooltip: 'Close and go home', onPressed: () => context.go('/home')),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          const _SuccessMark(),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            header: true,
            liveRegion: true,
            child: const Text('Order confirmed!', style: AppText.title, textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Thanks, $firstName. We’ll notify you when it ships.', style: AppText.bodyMuted, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xxl),
          _OrderCard(order: order),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(label: 'Track order', onPressed: () => context.go('/orders/${order.id}')),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: 'Continue shopping', variant: AppButtonVariant.outline, onPressed: () => context.go('/home')),
          const SizedBox(height: AppSpacing.sm),
          Center(child: TextButton(onPressed: () => context.go('/orders'), child: const Text('View all orders'))),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final n = order.itemCount;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.reference}', style: AppText.head),
                    Text('${formatDateTime(order.createdAt)} · $n ${n == 1 ? 'item' : 'items'}', style: AppText.meta),
                  ],
                ),
              ),
              Text(formatMoney(order.total), style: AppText.price),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            tint: true,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 22, color: AppColors.primaryDark),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated delivery', style: AppText.meta),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: formatDeliveryWindow(order.createdAt), style: AppText.head),
                        TextSpan(text: ' · ${formatPaymentMethod(order.paymentMethod)}', style: AppText.meta),
                      ])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Green check that pops in inside two soft rings (no animation when reduced motion is on).
class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      excludeSemantics: true,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: still ? 1 : 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, t, _) => SizedBox.square(
            dimension: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 0.6 + 0.4 * t.clamp(0, 1),
                  child: Container(decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: t.clamp(0, 1)), shape: BoxShape.circle)),
                ),
                Container(width: 84, height: 84, decoration: const BoxDecoration(color: Color(0xFFA7F3D0), shape: BoxShape.circle)),
                Transform.scale(
                  scale: 0.4 + 0.6 * t,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: AppColors.primaryDark, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 34, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
