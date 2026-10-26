import 'package:flutter/material.dart';

import '../../models/order/order.dart';
import '../../utils/formatters.dart';
import 'status_badge.dart';

/// Coloured pill for an order status: Pending (amber), Confirmed / Shipped (blue), Delivered (green).
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      OrderStatus.pending => BadgeTone.warning,
      OrderStatus.confirmed || OrderStatus.shipped => BadgeTone.info,
      OrderStatus.delivered => BadgeTone.success,
    };
    return StatusBadge(label: formatLabel(status.name), tone: tone);
  }
}
