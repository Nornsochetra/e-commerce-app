import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/main.dart';
import 'package:frontend_app/providers/auth/auth_provider.dart';
import 'package:frontend_app/services/api/api_client.dart';
import 'package:frontend_app/services/api/token_storage.dart';
import 'package:frontend_app/services/auth/dev_account.dart';
import 'package:frontend_app/services/cart/cart_service.dart';
import 'package:frontend_app/services/wishlist/wishlist_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Walks through the finished screens on a real simulator and saves screenshots for review.
/// Everything uses the real API, so start the backend first (see CLAUDE.md). The cart and wishlist
/// runs first put sample items on the dev account (prepareDevAccount).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester tester, [int ms = 1200]) async {
    for (var t = 0; t < ms; t += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Empty device storage and no saved sign-in (tokens live in secure storage, not SharedPreferences).
  Future<void> freshStart() async {
    await (await SharedPreferences.getInstance()).clear();
    await SecureTokenStorage().clear();
  }

  /// Puts the sample cart (1 Minimal Watch + 2 Canvas Backpacks) and wishlist (Cloud Sneakers,
  /// Classic Sunglasses) on the dev account, so the cart and wishlist screenshots have something to show.
  /// Uses the dev catalog seed's product ids (backend/src/main/resources/db/dev/R__dev_seed_catalog.sql).
  Future<void> prepareDevAccount() async {
    const watch = '11111111-1111-4111-8111-111111111111';
    const sneakers = '22222222-2222-4222-8222-222222222222';
    const backpack = '33333333-3333-4333-8333-333333333333';
    const sunglasses = '55555555-5555-4555-8555-555555555555';
    final api = ApiClient(tokens: MemoryTokenStorage());
    final login = await api.post('/auth/login', body: {'email': devAccountEmail, 'password': devAccountPassword}, auth: false);
    await api.tokens.save(TokenPair.fromJson(login as Map<String, dynamic>));
    final carts = CartService(api);
    for (final line in (await carts.getCart()).items) {
      await carts.removeItem(line.id);
    }
    await carts.addItem(watch, 1);
    await carts.addItem(backpack, 2);
    final wishlist = WishlistService(api);
    await wishlist.save(sneakers);
    await wishlist.save(sunglasses);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  testWidgets('slice 2: splash and sign-in screens', (tester) async {
    await freshStart();
    await tester.pumpWidget(ApmApp(authProvider: AuthProvider()));
    await wait(tester, 1100);
    await binding.takeScreenshot('s2_01_splash');
    await wait(tester, 2200);
    await binding.takeScreenshot('s2_02_login');

    await tap(tester, find.text('Sign in'));
    await wait(tester, 300);
    await binding.takeScreenshot('s2_03_login_errors');

    await tap(tester, find.text('Fill in'));
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass1');
    await tap(tester, find.text('Sign in'));
    await wait(tester, 800);
    await binding.takeScreenshot('s2_04_login_wrong_password');

    await tap(tester, find.text('Create an account'));
    await wait(tester, 800);
    await tester.enterText(find.byType(TextField).at(0), 'Sok Dara');
    await tester.enterText(find.byType(TextField).at(1), 'dara@example');
    await tester.enterText(find.byType(TextField).at(3), 'Passw0rd');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await wait(tester, 300);
    await binding.takeScreenshot('s2_05_register');
    await tap(tester, find.widgetWithText(TextButton, 'Create account'));
    await wait(tester, 300);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await wait(tester, 400);
    await binding.takeScreenshot('s2_06_register_errors');
  });

  testWidgets('slice 3: home, categories and product details', (tester) async {
    await freshStart();
    await tester.pumpWidget(ApmApp(authProvider: AuthProvider()));
    await wait(tester, 3300);
    await tap(tester, find.text('Fill in'));
    await tap(tester, find.text('Sign in'));
    await wait(tester, 2500); // product photos load from the network
    await binding.takeScreenshot('s3_01_home');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -520));
    await wait(tester, 1500);
    await binding.takeScreenshot('s3_02_home_trending');

    await tap(tester, find.byTooltip('Filter products'));
    await wait(tester, 2000);
    await binding.takeScreenshot('s3_03_categories_filter_sheet');
    await tap(tester, find.text('In stock only'));
    await wait(tester, 300);
    await tap(tester, find.textContaining('Show '));
    await wait(tester, 800);
    await binding.takeScreenshot('s3_04_categories_filtered');

    await tester.enterText(find.byType(TextField), 'zzz');
    await wait(tester, 400);
    await binding.takeScreenshot('s3_05_no_results');
    await tap(tester, find.text('Clear search & filters'));
    await wait(tester, 800);

    await tap(tester, find.bySemanticsLabel('View Minimal Watch'));
    await wait(tester, 1500);
    await binding.takeScreenshot('s3_06_product');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await wait(tester, 1000);
    await binding.takeScreenshot('s3_07_product_more');

    await tap(tester, find.byTooltip('Back'));
    await wait(tester, 800);
    await tap(tester, find.textContaining('Electronics'));
    await wait(tester, 800);
    await tap(tester, find.bySemanticsLabel('View Studio Headphones'));
    await wait(tester, 1500);
    await binding.takeScreenshot('s3_08_product_sold_out');
  });

  testWidgets('slice 4: cart, checkout, confirmation and orders', (tester) async {
    await freshStart();
    await prepareDevAccount();
    await tester.pumpWidget(ApmApp(authProvider: AuthProvider()));
    await wait(tester, 3300);
    await tap(tester, find.text('Fill in'));
    await tap(tester, find.text('Sign in'));
    await wait(tester, 1500);

    await tap(tester, find.bySemanticsLabel(RegExp('^Cart')));
    await wait(tester, 2000);
    await binding.takeScreenshot('s4_01_cart');
    await tap(tester, find.byTooltip('Remove Minimal Watch from cart'));
    await wait(tester, 600);
    await binding.takeScreenshot('s4_02_cart_removed_undo');
    await tap(tester, find.text('Undo'));
    await wait(tester, 600);

    await tap(tester, find.text('Checkout'));
    await wait(tester, 1500);
    await binding.takeScreenshot('s4_03_checkout');
    await tap(tester, find.text('Edit'));
    await tester.enterText(find.byType(TextField).at(2), 'Phnom');
    await tap(tester, find.text('Place order'));
    await wait(tester, 400);
    await binding.takeScreenshot('s4_04_checkout_errors');
    await tester.enterText(find.byType(TextField).at(2), '12 Riverside Street, Phnom Penh');
    await tap(tester, find.text('Place order'));
    await wait(tester, 2000);
    await binding.takeScreenshot('s4_05_order_confirmed');

    await tap(tester, find.text('Track order'));
    await wait(tester, 1500);
    await binding.takeScreenshot('s4_06_order_detail');
    await tap(tester, find.byTooltip('Go back'));
    await wait(tester, 1500);
    await binding.takeScreenshot('s4_07_orders');
  });

  testWidgets('slice 5: wishlist, notifications and profile', (tester) async {
    await freshStart();
    await prepareDevAccount();
    await tester.pumpWidget(ApmApp(authProvider: AuthProvider()));
    await wait(tester, 3300);
    await tap(tester, find.text('Fill in'));
    await tap(tester, find.text('Sign in'));
    await wait(tester, 1500);

    await tap(tester, find.bySemanticsLabel(RegExp('^Wishlist')));
    await wait(tester, 2000);
    await binding.takeScreenshot('s5_01_wishlist');

    await tap(tester, find.bySemanticsLabel(RegExp('^Profile')));
    await wait(tester, 1000);
    await binding.takeScreenshot('s5_02_profile');
    await tap(tester, find.text('Edit'));
    await wait(tester, 800);
    await tester.enterText(find.byType(TextField).at(1), 'alex@');
    await tap(tester, find.text('Save changes'));
    await wait(tester, 400);
    await binding.takeScreenshot('s5_03_edit_profile_errors');
    await tap(tester, find.text('Cancel'));
    await wait(tester, 800);
    await binding.takeScreenshot('s5_04_discard_changes');
    await tap(tester, find.text('Discard'));
    await wait(tester, 800);

    await tap(tester, find.byTooltip(RegExp('^Notifications')));
    await wait(tester, 1500);
    await binding.takeScreenshot('s5_05_notifications');

    await tap(tester, find.bySemanticsLabel(RegExp('^Profile')));
    await wait(tester, 800);
    await tap(tester, find.text('Log out'));
    await wait(tester, 800);
    await binding.takeScreenshot('s5_06_log_out_confirm');
  });
}
