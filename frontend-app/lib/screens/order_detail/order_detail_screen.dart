import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order/order_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/layout/app_header.dart';

/// PLACEHOLDER (slice 1). The status timeline, items and payment summary come in slice 4.
class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(orderId);
    return Scaffold(
      appBar: AppHeader(title: order == null ? 'Order' : '#${order.reference}', backFallback: '/orders'),
      body: Center(
        child: order == null
            ? const EmptyState(icon: Icons.search_off_rounded, title: 'Order not found', message: 'We couldn’t find that order.')
            : EmptyState(icon: Icons.local_shipping_outlined, title: formatLabel(order.status.name), message: '${order.itemCount} items · ${formatMoney(order.total)}\nThe full order details are built in slice 4.'),
      ),
    );
  }
}
