import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/cart/cart_provider.dart';
import 'bottom_nav_bar.dart';

/// Frame for the five tab screens (Home, Categories, Wishlist, Cart, Profile):
/// shows the current tab and the floating tab bar underneath. Built by router.dart.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    return Scaffold(
      extendBody: true, // screens scroll under the floating bar; they add bottom padding for it
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        cartCount: cartCount,
        // Tapping the current tab again returns to that tab's first screen.
        onTap: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
      ),
    );
  }
}
