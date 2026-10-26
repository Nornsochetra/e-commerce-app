import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/product/product.dart';
import '../../providers/wishlist/wishlist_provider.dart';
import '../../theme.dart';
import '../../utils/product_actions.dart';
import 'product_card.dart';

/// Two-column grid of [ProductCard]s inside a scrolling page. Tapping a card opens the product;
/// the heart and "Add" buttons use the shared wishlist / cart actions.
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  const ProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: AppSpacing.xl,
      crossAxisSpacing: 14,
      childAspectRatio: 0.58,
      children: [
        for (final p in products)
          ProductCard(
            product: p,
            isFavorite: wishlist.isSaved(p),
            onTap: () => context.push('/product/${p.id}'),
            onFavorite: () => toggleWishlistWithToast(context, p),
            onAdd: () => addToCartWithToast(context, p),
          ),
      ],
    );
  }
}
