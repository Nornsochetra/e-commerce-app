import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/order/order.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/notification/notification_provider.dart';
import '../../providers/order/order_provider.dart';
import '../../providers/product/product_provider.dart';
import '../../providers/user/user_provider.dart';
import '../../providers/wishlist/wishlist_provider.dart';
import '../../theme.dart';
import '../../utils/product_actions.dart';
import '../../widgets/buttons/circle_icon_button.dart';
import '../../widgets/cards/link_banner.dart';
import '../../widgets/cards/product_grid.dart';
import '../../widgets/cards/product_list_card.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/inputs/category_chip.dart';
import '../../widgets/inputs/search_bar.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/layout/brand_logo.dart';
import '../../widgets/layout/section_header.dart';
import 'widgets/hero_banner.dart';

/// SCR-007 Home: greeting, search entry, featured carousel, categories, order update,
/// "Trending now" grid and "New arrivals" list.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _greeting(DateTime now) => now.hour < 12 ? 'Good morning' : (now.hour < 18 ? 'Good afternoon' : 'Good evening');

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final signedIn = context.watch<AuthProvider>().isSignedIn;
    final user = context.watch<UserProvider>().user;
    final unread = context.watch<NotificationProvider>().unreadCount;
    final activeOrder = signedIn ? context.watch<OrderProvider>().activeOrder : null;

    final firstName = signedIn && user != null ? user.name.trim().split(' ').first : null;
    final greeting = _greeting(DateTime.now()) + (firstName == null ? '' : ', $firstName');

    return Scaffold(
      appBar: AppHeader(
        leading: const BrandLogo(),
        trailing: CircleIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: signedIn && unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
          badgeCount: signedIn ? unread : 0,
          onPressed: () => context.push('/notifications'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: products.load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
          children: [
            Text(greeting, style: AppText.meta),
            const SizedBox(height: AppSpacing.xs),
            Semantics(header: true, child: const Text('What are you shopping for today?', style: AppText.title)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: AppSearchBar(readOnly: true, onTap: () => context.go('/categories?focus=search'))),
                const SizedBox(width: 10),
                CircleIconButton(icon: Icons.tune_rounded, tooltip: 'Filter products', size: 48, onPressed: () => context.go('/categories?filters=open')),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const HeroBanner(),

            SectionHeader(title: 'Categories', actionLabel: 'See all', onAction: () => context.go('/categories')),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final c in products.categories) ...[
                    if (c != products.categories.first) const SizedBox(width: AppSpacing.sm),
                    CategoryChip(label: c.name, iconAsset: categoryIconAsset(c.slug), onTap: () => context.go('/categories?category=${c.slug}')),
                  ],
                ],
              ),
            ),

            if (activeOrder != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _OrderUpdate(order: activeOrder),
            ],

            SectionHeader(title: 'Trending now', actionLabel: 'See all', onAction: () => context.go('/categories')),
            if (products.isLoading)
              const ProductGridSkeleton()
            else if (products.error != null)
              EmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load products', message: 'Check your connection and try again.', actionLabel: 'Try again', onAction: products.load)
            else ...[
              ProductGrid(products: products.trending),
              const SectionHeader(title: 'New arrivals'),
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
          ],
        ),
      ),
    );
  }
}

/// "Order #MC-19842 · On the way to you" banner for the newest order that isn't delivered yet.
class _OrderUpdate extends StatelessWidget {
  final Order order;
  const _OrderUpdate({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.status == OrderStatus.shipped ? 'On the way to you' : 'Order ${order.status.name}';
    return LinkBanner(
      icon: Icons.local_shipping_outlined,
      semanticLabel: 'Order ${order.reference}: $status. View order',
      onTap: () => context.go('/orders/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order #${order.reference}', style: AppText.meta),
          Text(status, style: AppText.head),
        ],
      ),
    );
  }
}
