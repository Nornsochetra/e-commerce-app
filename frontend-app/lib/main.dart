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
        ChangeNotifierProvider(create: (_) => CartProvider()..load()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()..load()),
        ChangeNotifierProvider(create: (_) => OrderProvider()..load()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..load()),
        // The profile follows sign-in: loaded after signing in, cleared after signing out.
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, auth, user) => user!..syncWith(auth.status),
        ),
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
