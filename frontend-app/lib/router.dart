import 'package:go_router/go_router.dart';

import 'providers/auth/auth_provider.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/order_confirmed/order_confirmed_screen.dart';
import 'screens/order_detail/order_detail_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/product_detail/product_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/register/register_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/wishlist/wishlist_screen.dart';
import 'widgets/layout/main_shell.dart';

/// Screens a guest can't open; they are sent to /login first (requirement.md §7.2).
const _signInRequired = ['/cart', '/wishlist', '/profile', '/checkout', '/orders', '/notifications'];

bool _needsSignIn(String path) => _signInRequired.any((p) => path == p || path.startsWith('$p/'));

/// All screens of the app and how to reach them.
///
/// Tabs (with the floating tab bar): /home, /categories, /wishlist, /cart, /profile.
/// Screens opened from a tab keep the tab bar: /notifications (Home), /orders and /orders/:id (Profile).
/// Full-screen (no tab bar): splash, sign-in screens, /product/:id, /checkout, /orders/:id/confirmed.
GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth, // re-check the redirect when the user signs in or out
    redirect: (context, state) {
      final path = state.uri.path;
      if (auth.status == AuthStatus.unknown) return path == '/splash' ? null : '/splash';
      if (_needsSignIn(path) && !auth.isSignedIn) return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      if (auth.isSignedIn && (path == '/login' || path == '/register')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => LoginScreen(redirectTo: state.uri.queryParameters['from'])),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

      // The five tabs. Each branch keeps its own back stack.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/categories',
              builder: (context, state) => CategoriesScreen(
                category: state.uri.queryParameters['category'],
                focusSearch: state.uri.queryParameters['focus'] == 'search',
                openFilters: state.uri.queryParameters['filters'] == 'open',
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/wishlist', builder: (context, state) => const WishlistScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
            GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
            GoRoute(path: '/orders/:id', builder: (context, state) => OrderDetailScreen(orderId: state.pathParameters['id']!)),
          ]),
        ],
      ),

      // Full-screen pages shown over the tabs.
      GoRoute(path: '/product/:id', builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!)),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
      GoRoute(path: '/orders/:id/confirmed', builder: (context, state) => OrderConfirmedScreen(orderId: state.pathParameters['id']!)),
    ],
  );
}
