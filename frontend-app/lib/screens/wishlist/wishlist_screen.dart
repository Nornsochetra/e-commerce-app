import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/product/product_provider.dart';
import '../../providers/wishlist/wishlist_provider.dart';
import '../../theme.dart';
import '../../utils/product_actions.dart';
import '../../widgets/cards/product_list_card.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/layout/app_header.dart';

/// PLACEHOLDER (slice 1): saved products as list cards. Undo and "Add all" come in slice 5.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final products = context.watch<ProductProvider>();
    final saved = [for (final id in wishlist.productIds) ?products.productById(id)];
    return Scaffold(
      appBar: AppHeader(title: 'Wishlist', subtitle: saved.isEmpty ? null : '${saved.length} saved', showBack: false),
      body: saved.isEmpty
          ? Center(child: EmptyState(icon: Icons.favorite_border_rounded, danger: true, title: 'Nothing saved yet', message: 'Tap the heart on any product to keep it here for later.', actionLabel: 'Discover products', onAction: () => context.go('/categories')))
          : ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
              children: [
                for (final p in saved)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ProductListCard(
                      product: p,
                      isFavorite: true,
                      onTap: () => context.push('/product/${p.id}'),
                      onFavorite: () => toggleWishlistWithToast(context, p),
                      onAdd: () => addToCartWithToast(context, p),
                    ),
                  ),
              ],
            ),
    );
  }
}
