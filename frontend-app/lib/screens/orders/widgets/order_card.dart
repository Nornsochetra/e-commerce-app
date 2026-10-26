import 'package:flutter/material.dart';

import '../../../models/order/order.dart';
import '../../../theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/cards/product_image.dart';
import '../../../widgets/feedback/order_status_badge.dart';

/// Order history card: reference, date, item count, status, overlapping photos and total.
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = order.itemCount;
    final photos = order.items.take(3).toList();
    final extra = order.items.length - photos.length;

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
                          Text('${formatDate(order.createdAt)} · $n ${n == 1 ? 'item' : 'items'}', style: AppText.meta),
                        ],
                      ),
                    ),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    for (final (i, item) in photos.indexed)
                      Transform.translate(offset: Offset(-10.0 * i, 0), child: _Thumb(child: ProductImage(url: item.imageUrl))),
                    if (extra > 0)
                      Transform.translate(
                        offset: Offset(-10.0 * photos.length, 0),
                        child: _Thumb(
                          child: Container(
                            color: AppColors.field,
                            alignment: Alignment.center,
                            child: Text('+$extra', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                          ),
                        ),
                      ),
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

class _Thumb extends StatelessWidget {
  final Widget child;
  const _Thumb({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), border: Border.all(color: Colors.white, width: 2)),
        child: ClipRRect(borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 2), child: child),
      );
}
