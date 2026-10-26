import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/order/order_item.dart';
import '../../providers/order/order_provider.dart';
import '../../providers/product/product_provider.dart';
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

/// SCR-018 Order details (GET /orders/{id}): status timeline, items, delivery and payment summary.
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Always read the latest status from the server, even when the order is already known.
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? context.read<OrderProvider>().loadOrder(widget.orderId) : null);
  }

  @override
  void didUpdateWidget(OrderDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orderId != oldWidget.orderId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? context.read<OrderProvider>().loadOrder(widget.orderId) : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final products = context.watch<ProductProvider>();
    final orderId = widget.orderId;
    final o = orders.orderById(orderId);
    // Order lines from the API have no image, so the catalog photo is used.
    String imageOf(OrderItem item) => item.imageUrl.isNotEmpty ? item.imageUrl : (products.productById(item.productId)?.imageUrl ?? '');
    // Order lines have no photo: read each product once (skipped when it is already known).
    if (o != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final item in o.items) {
          final id = item.productId;
          if (imageOf(item).isEmpty && !products.isLoadingProduct(id) && !products.isMissing(id) && products.productError(id) == null) products.loadProduct(id);
        }
      });
    }

    if (o == null || orders.isMissing(orderId)) {
      final error = orders.orderError(orderId);
      return Scaffold(
        appBar: const AppHeader(title: 'Order', backFallback: '/orders'),
        body: orders.isMissing(orderId)
            ? ListView(children: [
                EmptyState(icon: Icons.inventory_2_outlined, title: 'Order not found', message: 'We couldn’t find that order.', actionLabel: 'Back to my orders', onAction: () => context.go('/orders')),
              ])
            : error != null
                ? ListView(children: [
                    EmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load this order', message: error, actionLabel: 'Try again', onAction: () => orders.loadOrder(orderId)),
                  ])
                : const Padding(padding: EdgeInsets.all(AppSpacing.page), child: ListSkeleton(count: 2)),
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
                            child: SizedBox.square(dimension: 56, child: ClipRRect(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), child: ProductImage(url: imageOf(item)))),
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
