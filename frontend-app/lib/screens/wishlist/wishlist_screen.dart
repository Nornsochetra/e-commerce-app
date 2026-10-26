import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/product/product.dart';
import '../../providers/cart/cart_provider.dart';
import '../../providers/product/product_provider.dart';
import '../../providers/wishlist/wishlist_provider.dart';
import '../../theme.dart';
import '../../utils/product_actions.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/product_list_card.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/layout/app_header.dart';

/// SCR-014 Wishlist: saved products (newest first), remove with Undo, add one or all in-stock items to the cart.
/// Sold-out products stay in the list, but their cart button is disabled.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  Future<void> _remove(BuildContext context, Product p) async {
    final wishlist = context.read<WishlistProvider>();
    final index = await wishlist.remove(p.id);
    if (index == -1 || !context.mounted) return;
    showAppToast(context, 'Removed from wishlist', actionLabel: 'Undo', onAction: () => wishlist.restore(p.id, index));
  }

  Future<void> _addAll(BuildContext context, List<Product> products) async {
    final cart = context.read<CartProvider>();
    var added = 0;
    for (final p in products) {
      final result = await cart.add(p);
      if (result == AddToCartResult.added || result == AddToCartResult.updated) added++;
    }
    if (!context.mounted) return;
    if (added == 0) {
      showAppToast(context, 'Your cart already has all the stock available');
    } else {
      showAppToast(context, 'Added $added ${added == 1 ? 'item' : 'items'} to cart', actionLabel: 'View cart', onAction: () => context.go('/cart'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final products = context.watch<ProductProvider>();
    final saved = [for (final id in wishlist.newestFirst) ?products.productById(id)];
    final inStock = saved.where((p) => p.inStock).toList();
    final loading = (wishlist.isLoading || products.isLoading) && saved.isEmpty;

    return Scaffold(
      appBar: AppHeader(title: 'Wishlist', subtitle: saved.isEmpty ? null : '${saved.length} saved', showBack: false),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          if (loading)
            const ListSkeleton()
          else if (saved.isEmpty)
            EmptyState(
              icon: Icons.favorite_border_rounded,
              danger: true,
              title: 'Nothing saved yet',
              message: 'Tap the heart on any product to keep it here for later.',
              actionLabel: 'Discover products',
              onAction: () => context.go('/categories'),
            )
          else ...[
            for (final p in saved)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ProductListCard(
                  key: ValueKey(p.id),
                  product: p,
                  isFavorite: true,
                  onTap: () => context.push('/product/${p.id}'),
                  onFavorite: () => _remove(context, p),
                  onAdd: () => addToCartWithToast(context, p),
                ),
              ),
            if (inStock.length > 1) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Add all in stock to cart (${inStock.length})',
                icon: Icons.add_shopping_cart_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => _addAll(context, inStock),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
