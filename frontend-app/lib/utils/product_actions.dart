import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product/product.dart';
import '../providers/auth/auth_provider.dart';
import '../providers/cart/cart_provider.dart';
import '../providers/wishlist/wishlist_provider.dart';
import '../widgets/feedback/app_toast.dart';

/// Shared "Add to cart" and "Save to wishlist" actions with the same feedback everywhere.
/// Guests are sent to sign in first, because cart and wishlist need an account.

bool _requireSignIn(BuildContext context) {
  if (context.read<AuthProvider>().isSignedIn) return true;
  final from = GoRouterState.of(context).uri.toString();
  context.push('/login?from=${Uri.encodeComponent(from)}');
  return false;
}

Future<void> addToCartWithToast(BuildContext context, Product product, {int quantity = 1}) async {
  if (!_requireSignIn(context)) return;
  final result = await context.read<CartProvider>().add(product, quantity: quantity);
  if (!context.mounted) return;
  switch (result) {
    case AddToCartResult.outOfStock:
      showAppToast(context, '${product.name} is out of stock');
    case AddToCartResult.maxReached:
      showAppToast(context, 'Maximum stock already in your cart');
    case AddToCartResult.added || AddToCartResult.updated:
      showAppToast(context, result == AddToCartResult.added ? 'Added to cart' : 'Cart quantity updated',
          actionLabel: 'View cart', onAction: () => context.go('/cart'));
  }
}

Future<void> toggleWishlistWithToast(BuildContext context, Product product) async {
  if (!_requireSignIn(context)) return;
  final saved = await context.read<WishlistProvider>().toggle(product.id);
  if (context.mounted) showAppToast(context, saved ? 'Saved to wishlist' : 'Removed from wishlist');
}
