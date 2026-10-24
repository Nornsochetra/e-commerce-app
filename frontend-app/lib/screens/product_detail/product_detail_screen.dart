import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/product/product_provider.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../utils/product_actions.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/product_image.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/inputs/quantity_stepper.dart';
import '../../widgets/layout/action_dock.dart';
import '../../widgets/layout/app_header.dart';

/// PLACEHOLDER (slice 1): photo, name, price and the Add-to-cart dock (no tab bar).
/// The full product page comes in slice 3.
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProductProvider>().productById(widget.productId);
    if (p == null) {
      return const Scaffold(
        appBar: AppHeader(title: 'Product', backFallback: '/categories'),
        body: Center(child: EmptyState(icon: Icons.search_off_rounded, title: 'Product not found', message: 'This product may no longer be available.')),
      );
    }
    return Scaffold(
      appBar: AppHeader(title: p.name, backFallback: '/categories'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, AppSpacing.xxl),
        children: [
          AspectRatio(aspectRatio: 1, child: ClipRRect(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), child: ProductImage(url: p.imageUrl, semanticLabel: p.name))),
          const SizedBox(height: AppSpacing.xl),
          Text(p.name, style: AppText.display),
          const SizedBox(height: AppSpacing.sm),
          Text(formatMoney(p.price), style: AppText.price.copyWith(fontSize: 26)),
          const SizedBox(height: AppSpacing.md),
          Text(p.description ?? 'No description has been added for this product yet.', style: AppText.bodyMuted),
        ],
      ),
      bottomNavigationBar: ActionDock(
        children: p.inStock
            ? [
                QuantityStepper(value: _quantity, max: p.availableQuantity, onChanged: (q) => setState(() => _quantity = q)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: AppButton(label: 'Add to cart · ${formatMoney(p.price * _quantity)}', onPressed: () => addToCartWithToast(context, p, quantity: _quantity))),
              ]
            : const [Expanded(child: Text('Out of stock', style: AppText.head))],
      ),
    );
  }
}
