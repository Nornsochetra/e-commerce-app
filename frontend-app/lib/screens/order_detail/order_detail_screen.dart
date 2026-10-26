import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/order/order_provider.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/cards/price_summary.dart';
import '../../widgets/cards/product_image.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/feedback/order_status_badge.dart';
import '../../widgets/layout/app_header.dart';
import 'widgets/order_status_timeline.dart';

/// SCR-018 Order details: status timeline, items, delivery and payment summary.
class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final o = orders.orderById(orderId);

    if (o == null) {
      return Scaffold(
        appBar: const AppHeader(title: 'Order', backFallback: '/orders'),
        body: orders.isLoading
            ? const Padding(padding: EdgeInsets.all(AppSpacing.page), child: ListSkeleton(count: 2))
            : ListView(children: [
                EmptyState(icon: Icons.inventory_2_outlined, title: 'Order not found', message: 'We couldn’t find that order.', actionLabel: 'Back to my orders', onAction: () => context.go('/orders')),
              ]),
      );
    }

    return Scaffold(
      appBar: AppHeader(title: '#${o.reference}', subtitle: formatDate(o.createdAt), backFallback: '/orders'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Semantics(header: true, child: const Text('Order status', style: AppText.head))),
                    OrderStatusBadge(status: o.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                OrderStatusTimeline(order: o),
              ],
            ),
          ),

          _Label('Items · ${o.itemCount}'),
          AppCard(
            child: Column(
              children: [
                for (final (i, item) in o.items.indexed)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.md),
                    child: Row(
                      children: [
                        Semantics(
                          button: true,
                          label: 'View ${item.name}',
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: () => context.push('/product/${item.productId}'),
                            child: SizedBox.square(dimension: 56, child: ClipRRect(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), child: ProductImage(url: item.imageUrl))),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: AppText.head, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${item.quantity} × ${formatMoney(item.unitPrice)}', style: AppText.meta),
                            ],
                          ),
                        ),
                        Text(formatMoney(item.lineTotal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const _Label('Delivery'),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  child: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primaryDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.recipientName, style: AppText.head),
                      Text(o.email, style: AppText.meta),
                      Text(o.address, style: AppText.meta),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Standard delivery · ${formatPaymentMethod(o.paymentMethod)}', style: AppText.meta),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const _Label('Payment summary'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PriceSummary(rows: [('Subtotal', formatMoney(o.subtotal)), ('Delivery fee', formatMoney(o.deliveryFee))], total: o.total),
                const SizedBox(height: AppSpacing.md),
                Text('Last updated ${formatDateTime(o.updatedAt)}', style: AppText.meta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xxl, AppSpacing.xs, AppSpacing.sm),
        child: Semantics(header: true, child: Text(text.toUpperCase(), style: AppText.meta.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.7))),
      );
}
