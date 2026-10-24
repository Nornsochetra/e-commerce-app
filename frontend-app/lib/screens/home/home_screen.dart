import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/notification/notification_provider.dart';
import '../../providers/product/product_provider.dart';
import '../../providers/wishlist/wishlist_provider.dart';
import '../../theme.dart';
import '../../utils/product_actions.dart';
import '../../widgets/buttons/circle_icon_button.dart';
import '../../widgets/cards/product_card.dart';
import '../../widgets/cards/product_list_card.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/inputs/category_chip.dart';
import '../../widgets/inputs/search_bar.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/brand_logo.dart';

/// PLACEHOLDER (slice 1): shows the shared widgets with real data so they can be reviewed.
/// The full Home layout (greeting, banner carousel, order update) comes in slice 3.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      appBar: AppHeader(
        leading: const BrandLogo(),
        trailing: CircleIconButton(icon: Icons.notifications_none_rounded, tooltip: 'Notifications', badgeCount: unread, onPressed: () => context.push('/notifications')),
      ),
      body: RefreshIndicator(
        onRefresh: products.load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
          children: [
            AppSearchBar(readOnly: true, onTap: () => context.go('/categories?focus=search')),
            const SizedBox(height: AppSpacing.xl),
            const Text('Categories', style: AppText.section),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final c in products.categories) ...[
                    CategoryChip(label: c.name, iconAsset: categoryIconAsset(c.slug), onTap: () => context.go('/categories?category=${c.slug}')),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text('Trending now', style: AppText.section),
            const SizedBox(height: AppSpacing.md),
            if (products.isLoading)
              const ProductGridSkeleton()
            else if (products.error != null)
              EmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load products', message: products.error!, actionLabel: 'Try again', onAction: products.load)
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.xl,
                crossAxisSpacing: 14,
                childAspectRatio: 0.58,
                children: [
                  for (final p in products.trending)
                    ProductCard(
                      product: p,
                      isFavorite: wishlist.contains(p.id),
                      onTap: () => context.push('/product/${p.id}'),
                      onFavorite: () => toggleWishlistWithToast(context, p),
                      onAdd: () => addToCartWithToast(context, p),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.xxl),
            const Text('New arrivals', style: AppText.section),
            const SizedBox(height: AppSpacing.md),
            if (products.isLoading)
              const ListSkeleton(count: 2)
            else
              for (final p in products.newArrivals)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ProductListCard(
                    product: p,
                    isFavorite: wishlist.contains(p.id),
                    onTap: () => context.push('/product/${p.id}'),
                    onFavorite: () => toggleWishlistWithToast(context, p),
                    onAdd: () => addToCartWithToast(context, p),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
