import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/product/product_provider.dart';
import '../../providers/wishlist/wishlist_provider.dart';
import '../../theme.dart';
import '../../utils/product_actions.dart';
import '../../widgets/cards/product_card.dart';
import '../../widgets/inputs/category_chip.dart';
import '../../widgets/layout/app_header.dart';

/// PLACEHOLDER (slice 1): category chips + product grid so tabs and links can be tested.
/// Search, sort and the filter sheet come in slice 3.
class CategoriesScreen extends StatefulWidget {
  final String? category; // category slug from /categories?category=bags
  final bool focusSearch; // /categories?focus=search (used in slice 3)
  final bool openFilters; // /categories?filters=open (used in slice 3)

  const CategoriesScreen({super.key, this.category, this.focusSearch = false, this.openFilters = false});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late String? _slug = widget.category;

  @override
  void didUpdateWidget(CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) _slug = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final shown = products.products.where((p) => _slug == null || products.categories.any((c) => c.slug == _slug && c.id == p.categoryId)).toList();

    return Scaffold(
      appBar: const AppHeader(title: 'Categories', showBack: false),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              CategoryChip(label: 'All', selected: _slug == null, onTap: () => setState(() => _slug = null)),
              for (final c in products.categories)
                CategoryChip(label: c.name, iconAsset: categoryIconAsset(c.slug), selected: _slug == c.slug, onTap: () => setState(() => _slug = c.slug)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('${shown.length} products', style: AppText.meta),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.xl,
            crossAxisSpacing: 14,
            childAspectRatio: 0.58,
            children: [
              for (final p in shown)
                ProductCard(
                  product: p,
                  isFavorite: wishlist.contains(p.id),
                  onTap: () => context.push('/product/${p.id}'),
                  onFavorite: () => toggleWishlistWithToast(context, p),
                  onAdd: () => addToCartWithToast(context, p),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
