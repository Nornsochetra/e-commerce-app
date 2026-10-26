import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth/auth_provider.dart';
import 'providers/cart/cart_provider.dart';
import 'providers/notification/notification_provider.dart';
import 'providers/order/order_provider.dart';
import 'providers/product/product_provider.dart';
import 'providers/user/user_provider.dart';
import 'providers/wishlist/wishlist_provider.dart';
import 'router.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  runApp(ApmApp(authProvider: authProvider));
}

/// Root widget: creates every provider (and loads its data), then the themed app with the router.
class ApmApp extends StatefulWidget {
  final AuthProvider authProvider;
  const ApmApp({super.key, required this.authProvider});

  @override
  State<ApmApp> createState() => _ApmAppState();
}

class _ApmAppState extends State<ApmApp> {
  late final _router = createRouter(widget.authProvider);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        // The catalog loads when a screen needs it, and what's on screen is re-read when someone signs
        // in or out, so the `saved` hearts belong to the right person.
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(create: (_) => ProductProvider(), update: (_, auth, p) => p!..syncAuth(auth.status)),
        // The customer's own data follows sign-in: each screen loads what it shows when it opens, and
        // it is cleared for guests and after signing out (providers/auth/follows_sign_in.dart).
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(create: (_) => CartProvider(), update: (_, auth, p) => p!..syncWith(auth.status)),
        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(create: (_) => WishlistProvider(), update: (_, auth, p) => p!..syncWith(auth.status)),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(create: (_) => OrderProvider(), update: (_, auth, p) => p!..syncWith(auth.status)),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(create: (_) => NotificationProvider(), update: (_, auth, p) => p!..syncWith(auth.status)),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(create: (_) => UserProvider(), update: (_, auth, p) => p!..syncWith(auth.status)),
      ],
      child: MaterialApp.router(
        title: 'APM',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: _router,
      ),
    );
  }
}
