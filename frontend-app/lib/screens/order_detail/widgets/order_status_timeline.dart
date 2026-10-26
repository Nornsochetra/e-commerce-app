import 'package:flutter/material.dart';

import '../../../models/order/order.dart';
import '../../../theme.dart';
import '../../../utils/formatters.dart';

const _stages = [
  (OrderStatus.pending, 'Order placed', 'We received your order'),
  (OrderStatus.confirmed, 'Confirmed', 'Your order is being prepared'),
  (OrderStatus.shipped, 'Shipped', 'On its way with our courier'),
  (OrderStatus.delivered, 'Delivered', 'Handed over to you'),
];

/// Vertical pending → confirmed → shipped → delivered steps. Finished steps are green;
/// the current one has a mint ring and, until delivery, the estimated delivery window.
class OrderStatusTimeline extends StatelessWidget {
  final Order order;
  const OrderStatusTimeline({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final at = _stages.indexWhere((s) => s.$1 == order.status);
    return Column(
      children: [
        for (final (i, (status, title, text)) in _stages.indexed)
          _Step(
            number: i + 1,
            title: title,
            text: i == at && status != OrderStatus.delivered ? '$text · est. ${formatDeliveryWindow(order.createdAt)}' : text,
            done: i <= at,
            current: i == at,
            last: i == _stages.length - 1,
            lineDone: i < at,
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String text;
  final bool done;
  final bool current;
  final bool last;
  final bool lineDone; // the line below this step leads to a finished step

  const _Step({required this.number, required this.title, required this.text, required this.done, required this.current, required this.last, required this.lineDone});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title${current ? ', current step' : done ? ', done' : ''}. $text',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done ? AppColors.primaryDark : AppColors.field,
                      shape: BoxShape.circle,
                      boxShadow: current ? const [BoxShadow(color: AppColors.mint, spreadRadius: 5)] : null,
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : Text('$number', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textFaint)),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(width: 2, margin: const EdgeInsets.only(top: 2), color: lineDone ? AppColors.primary : AppColors.line),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 3, bottom: last ? 0 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: done ? AppColors.text : AppColors.textMuted)),
                    Text(text, style: AppText.meta),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
