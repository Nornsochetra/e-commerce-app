import 'package:flutter/material.dart';

import '../../../models/order/order.dart';
import '../../../theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/feedback/order_status_badge.dart';

/// Order history card: reference, date, item count, status and total.
/// Order history from the API has no item lines, so a parcel icon stands in for product photos.
class OrderCard extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback onTap;
  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = order.itemCount;
    return Semantics(
      button: true,
      label: 'Order ${order.reference}, ${formatLabel(order.status.name)}, ${formatMoney(order.total)}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg), side: const BorderSide(color: AppColors.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${order.reference}', style: AppText.head),
                          const SizedBox(height: 2),
                          Text(formatDate(order.createdAt), style: AppText.meta),
                        ],
                      ),
                    ),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('$n ${n == 1 ? 'item' : 'items'}', style: AppText.bodyMuted),
                    const Spacer(),
                    Text(formatMoney(order.total), style: AppText.price),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textFaint),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
