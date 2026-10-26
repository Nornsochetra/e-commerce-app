import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/cart/cart_item.dart';
import '../../providers/cart/cart_provider.dart';
import '../../providers/wishlist/wishlist_provider.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/cards/price_summary.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/layout/action_dock.dart';
import '../../widgets/layout/app_header.dart';
import 'widgets/cart_item_tile.dart';

/// SCR-013 Shopping cart: change quantity, remove with Undo, save for later, order summary
/// and a Checkout dock above the tab bar.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  String _items(int n) => '$n ${n == 1 ? 'item' : 'items'}';

  Future<void> _remove(BuildContext context, CartItem item) async {
    final cart = context.read<CartProvider>();
    final removed = await cart.remove(item.productId);
    if (!context.mounted) return;
    if (removed == null) return showAppToast(context, cart.lastError ?? 'Couldn’t remove that item. Please try again.');
    showAppToast(context, 'Removed from cart', actionLabel: 'Undo', onAction: () => cart.restore(removed));
  }

  /// Moves the item to the wishlist; Undo puts it back in the cart (and un-saves it if it wasn't saved before).
  Future<void> _saveForLater(BuildContext context, CartItem item) async {
    final cart = context.read<CartProvider>();
    final wishlist = context.read<WishlistProvider>();
    final wasSaved = wishlist.contains(item.productId);
    if (!wasSaved) {
      final error = await wishlist.save(item.productId);
      if (error != null) return context.mounted ? showAppToast(context, error) : null;
    }
    final removed = await cart.remove(item.productId);
    if (!context.mounted) return;
    if (removed == null) return showAppToast(context, cart.lastError ?? 'Couldn’t move that item. Please try again.');
    showAppToast(context, 'Moved to wishlist', actionLabel: 'Undo', onAction: () {
      cart.restore(removed);
      if (!wasSaved) wishlist.remove(item.productId);
    });
  }

  Future<void> _setQuantity(BuildContext context, CartItem item, int quantity) async {
    final error = await context.read<CartProvider>().setQuantity(item.productId, quantity);
    if (error != null && context.mounted) showAppToast(context, error);
  }

  // Own messenger: toasts show above the Checkout dock instead of being covered by it.
  @override
  Widget build(BuildContext context) => ScaffoldMessenger(child: Builder(builder: _buildScaffold));

  Widget _buildScaffold(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final hasItems = cart.items.isNotEmpty;

    return Scaffold(
      appBar: AppHeader(title: 'My Cart', subtitle: hasItems ? _items(cart.itemCount) : null, showBack: false),
      body: cart.isLoading && !hasItems
          ? const Padding(padding: EdgeInsets.all(AppSpacing.page), child: ListSkeleton(count: 2))
          : cart.error != null && !hasItems
          ? ListView(children: [
              EmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load your cart', message: cart.error!, actionLabel: 'Try again', onAction: cart.load),
            ])
          : !hasItems
              ? ListView(
                  children: [
                    EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your cart is empty',
                      message: 'Browse the shop and tap Add on anything you like.',
                      actionLabel: 'Start shopping',
                      onAction: () => context.go('/categories'),
                    ),
                    Center(child: TextButton(onPressed: () => context.go('/wishlist'), child: const Text('View wishlist'))),
                  ],
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
                  children: [
                    for (final item in cart.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: CartItemTile(
                          key: ValueKey(item.productId),
                          item: item,
                          onOpen: () => context.push('/product/${item.productId}'),
                          busy: cart.isUpdating(item.productId),
                          onQuantity: (q) => _setQuantity(context, item, q),
                          onRemove: () => _remove(context, item),
                          onSaveForLater: () => _saveForLater(context, item),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(header: true, child: const Text('Order summary', style: AppText.head)),
                          const SizedBox(height: AppSpacing.md),
                          PriceSummary(
                            rows: [
                              ('Subtotal · ${_items(cart.itemCount)}', formatMoney(cart.subtotal)),
                              ('Delivery · standard', formatMoney(cart.deliveryFee)),
                              ('Discounts', 'None available'),
                            ],
                            total: cart.total,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Row(
                      children: [
                        SizedBox(width: AppSpacing.xs),
                        Icon(Icons.verified_user_outlined, size: 16, color: AppColors.textMuted),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text('Totals are confirmed at checkout. Pay with cash on delivery.', style: AppText.meta)),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(onPressed: () => context.go('/categories'), child: const Text('Continue shopping')),
                    ),
                  ],
                ),
      bottomNavigationBar: hasItems
          ? ActionDock(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    Text(formatMoney(cart.total), style: AppText.price.copyWith(fontSize: 18)),
                  ],
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: AppButton(label: 'Checkout', icon: Icons.arrow_forward_rounded, onPressed: () => context.push('/checkout'))),
              ],
            )
          : null,
    );
  }
}
