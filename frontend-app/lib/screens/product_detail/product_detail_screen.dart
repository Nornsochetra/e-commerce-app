import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart' show deliveryFeeUsd;
import '../../models/product/product.dart';
import '../../providers/cart/cart_provider.dart';
import '../../providers/product/product_provider.dart';
import '../../providers/wishlist/wishlist_provider.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../utils/product_actions.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/buttons/circle_icon_button.dart';
import '../../widgets/cards/link_banner.dart';
import '../../widgets/cards/product_grid.dart';
import '../../widgets/cards/product_image.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/feedback/status_badge.dart';
import '../../widgets/inputs/quantity_stepper.dart';
import '../../widgets/layout/action_dock.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/section_header.dart';

/// SCR-010 Product details: photo, name, rating, stock, price, description, delivery info,
/// "You may also like", and a sticky dock with quantity + Add to cart (or Save for later when sold out).
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _goBack() => context.canPop() ? context.pop() : context.go('/categories');

  @override
  void initState() {
    super.initState();
    // Reads the product with its description and current stock (GET /products/{id}).
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? context.read<ProductProvider>().loadProduct(widget.productId) : null);
  }

  @override
  void didUpdateWidget(ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.productId != oldWidget.productId) {
      _quantity = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? context.read<ProductProvider>().loadProduct(widget.productId) : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final id = widget.productId;
    // A product seen in a list shows straight away; the details call then adds the description.
    final p = products.productById(id);
    final error = products.productError(id);

    if (p == null || products.isMissing(id)) {
      return Scaffold(
        appBar: const AppHeader(title: 'Product', backFallback: '/categories'),
        body: products.isMissing(id)
            ? EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Product not found',
                message: 'This product may no longer be available.',
                actionLabel: 'Browse products',
                onAction: () => context.go('/categories'),
              )
            : error != null
                ? EmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load this product', message: error, actionLabel: 'Try again', onAction: () => products.loadProduct(id))
                : const Padding(padding: EdgeInsets.all(AppSpacing.page), child: SkeletonBox(aspectRatio: 1, radius: AppSpacing.radiusXl)),
      );
    }

    final isFavorite = context.watch<WishlistProvider>().contains(p.id);
    final inCart = context.watch<CartProvider>().quantityOf(p.id);
    final related = products.related(p);
    final quantity = math.min(_quantity, math.max(1, p.availableQuantity)); // stock may have dropped

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          _PhotoHeader(product: p, isFavorite: isFavorite, onBack: _goBack),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xl, AppSpacing.page, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Summary(product: p),
                const SizedBox(height: AppSpacing.xl),
                const _Highlights(),
                const SizedBox(height: AppSpacing.xl),
                _Details(product: p),
                if (inCart > 0) ...[
                  const SizedBox(height: AppSpacing.xl),
                  LinkBanner(
                    icon: Icons.shopping_bag_outlined,
                    actionLabel: 'View cart',
                    semanticLabel: '$inCart already in your cart. View cart',
                    onTap: () => context.go('/cart'),
                    child: Text.rich(TextSpan(style: AppText.body, children: [
                      TextSpan(text: '$inCart', style: const TextStyle(fontWeight: FontWeight.w800)),
                      const TextSpan(text: ' already in your cart'),
                    ])),
                  ),
                ],
                if (related.isNotEmpty) ...[
                  const SectionHeader(title: 'You may also like'),
                  ProductGrid(products: related),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ActionDock(
        children: p.inStock
            ? [
                QuantityStepper(value: quantity, max: p.availableQuantity, productName: p.name, onChanged: (q) => setState(() => _quantity = q)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: AppButton(label: 'Add to cart · ${formatMoney(p.price * quantity)}', onPressed: () => addToCartWithToast(context, p, quantity: quantity))),
              ]
            : [
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Out of stock', style: AppText.head),
                      Text('Save it to your wishlist for later', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppButton(
                  label: isFavorite ? 'Saved' : 'Save for later',
                  icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  variant: AppButtonVariant.secondary,
                  expanded: false,
                  onPressed: () => toggleWishlistWithToast(context, p),
                ),
              ],
      ),
    );
  }
}

/// Edge-to-edge photo with round Back and heart buttons floating on it.
class _PhotoHeader extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onBack;
  const _PhotoHeader({required this.product, required this.isFavorite, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SizedBox(
      height: math.min(size.width, size.height * 0.58),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl)),
              child: ProductImage(url: product.imageUrl, semanticLabel: product.name),
            ),
          ),
          Positioned(
            left: AppSpacing.page,
            right: AppSpacing.page,
            top: MediaQuery.paddingOf(context).top + AppSpacing.md,
            child: Row(
              children: [
                CircleIconButton(icon: Icons.chevron_left_rounded, tooltip: 'Back', style: CircleButtonStyle.onImage, onPressed: onBack),
                const Spacer(),
                CircleIconButton(
                  icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: isFavorite ? AppColors.error : AppColors.text,
                  tooltip: isFavorite ? 'Remove ${product.name} from wishlist' : 'Save ${product.name} to wishlist',
                  style: CircleButtonStyle.onImage,
                  onPressed: () => toggleWishlistWithToast(context, product),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Category and badges, name, rating, stock, price and the description (left out when there is none).
class _Summary extends StatelessWidget {
  final Product product;
  const _Summary({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final (String stockLabel, BadgeTone stockTone) = !p.inStock
        ? ('Out of stock', BadgeTone.error)
        : p.lowStock
            ? ('Only ${p.availableQuantity} left', BadgeTone.warning)
            : ('In stock', BadgeTone.success);
    final description = p.description?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(p.categoryName.toUpperCase(), style: AppText.eyebrow),
            for (final b in p.badgesInOrder) StatusBadge(label: formatLabel(b)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(header: true, child: Text(p.name, style: AppText.display)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 18, color: AppColors.star),
            const SizedBox(width: 3),
            Text(p.rating?.toStringAsFixed(1) ?? 'Not rated', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('•', style: TextStyle(color: AppColors.textFaint))),
            StatusBadge(label: stockLabel, tone: stockTone),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text.rich(TextSpan(children: [
          TextSpan(text: formatMoney(p.price), style: AppText.price.copyWith(fontSize: 28, height: 34 / 28)),
          const TextSpan(text: '  / each', style: AppText.meta),
        ])),
        if (description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(description, style: AppText.bodyMuted),
        ],
      ],
    );
  }
}

/// Mint card: delivery time and fee, cash on delivery.
class _Highlights extends StatelessWidget {
  const _Highlights();

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, InlineSpan text) => Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
              child: Icon(icon, size: 20, color: AppColors.primaryDark),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text.rich(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text))),
          ],
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: Column(
        children: [
          row(Icons.local_shipping_outlined, TextSpan(text: 'Standard delivery in 2–4 business days', children: [
            TextSpan(text: ' · ${formatMoney(deliveryFeeUsd)}', style: const TextStyle(color: AppColors.textMuted)),
          ])),
          const SizedBox(height: AppSpacing.md),
          row(Icons.payments_outlined, const TextSpan(text: 'Pay with cash on delivery')),
        ],
      ),
    );
  }
}

/// "Product details" and "Delivery & payment" sections that open and close.
class _Details extends StatelessWidget {
  final Product product;
  const _Details({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    const line = BorderSide(color: AppColors.line);
    Widget section(String title, Widget body, {bool last = false}) => ExpansionTile(
          title: Text(title, style: AppText.head),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: AppSpacing.lg),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: AppColors.textMuted,
          collapsedIconColor: AppColors.textMuted,
          shape: Border(top: line, bottom: last ? line : BorderSide.none),
          collapsedShape: Border(top: line, bottom: last ? line : BorderSide.none),
          children: [body],
        );

    Widget fact(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppText.bodyMuted)),
              Text(value, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return Column(
      children: [
        section(
          'Product details',
          Column(children: [
            fact('Category', p.categoryName),
            fact('Availability', p.inStock ? '${p.availableQuantity} in stock' : 'Out of stock'),
            fact('Rating', '${p.rating?.toStringAsFixed(1) ?? '–'} / 5'),
            fact('Currency', 'USD'),
          ]),
        ),
        section(
          'Delivery & payment',
          Text(
            'Orders ship by standard delivery in 2–4 business days for a flat ${formatMoney(deliveryFeeUsd)}. '
            'Cash on delivery is the only payment method in this version.',
            style: AppText.bodyMuted,
          ),
          last: true,
        ),
      ],
    );
  }
}
