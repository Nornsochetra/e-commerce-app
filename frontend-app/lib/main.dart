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
        ChangeNotifierProvider(create: (_) => ProductProvider()..load()),
        // The customer's own data follows sign-in: loaded after signing in, cleared for guests and
        // after signing out (providers/auth/follows_sign_in.dart).
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
