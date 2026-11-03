import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/widgets/buttons/app_button.dart';
import 'package:frontend_app/widgets/layout/bottom_nav_bar.dart';

import '../helpers.dart';

void main() {
  testWidgets('signing in loads only what Home shows; each tab loads its own data when opened', (tester) async {
    final backend = await startSignedIn(tester);
    Set<String> requested() => backend.adapter.requests.map((r) => '${r.method} ${r.path}').toSet();

    expect(requested(), containsAll(['GET /auth/me', 'GET /categories', 'GET /products', 'GET /orders', 'GET /notifications/unread-count']));
    expect(requested(), isNot(anyOf(contains('GET /cart'), contains('GET /wishlist/items'), contains('GET /notifications'))));
    // The cart badge comes from the counts in GET /auth/me, so no cart request was needed for it.
    expect(find.descendant(of: find.byType(BottomNavBar), matching: find.text('3')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Cart')));
    await wait(tester);
    expect(backend.calls('GET', '/cart'), 1);
    expect(find.text('Minimal Watch'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Wishlist')));
    await wait(tester);
    expect(backend.calls('GET', '/wishlist/items'), 1);
    expect(find.text('2 saved'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Cart'))); // coming back doesn't load it again
    await wait(tester);
    expect(backend.calls('GET', '/cart'), 1);

    // No list is ever requested all at once: every page is at most 20 items.
    final sizes = backend.adapter.requests.map((r) => r.queryParameters['size']).whereType<int>();
    expect(sizes, everyElement(lessThanOrEqualTo(20)));
  });

  testWidgets('logging out sends only the logout request (nothing is re-read for the Sign in screen)', (tester) async {
    final backend = await startSignedIn(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Profile')));
    await wait(tester);
    await tester.dragUntilVisible(find.widgetWithText(AppButton, 'Log out'), find.byType(Scrollable).first, const Offset(0, -200));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'Log out'));
    await wait(tester, steps: 2);

    final before = backend.adapter.requests.length;
    await tester.tap(find.widgetWithText(AppButton, 'Log out').last); // confirm
    await wait(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(backend.adapter.requests.skip(before).map((r) => '${r.method} ${r.path}'), ['POST /auth/logout']);
  });

  testWidgets('signing in after browsing Categories as a guest loads only Home; the search re-runs when Categories opens', (tester) async {
    final backend = await startAsGuest(tester);
    await tester.tap(find.descendant(of: find.byType(BottomNavBar), matching: find.bySemanticsLabel(RegExp('^Categories'))));
    await wait(tester);
    await tester.tap(find.descendant(of: find.byType(BottomNavBar), matching: find.bySemanticsLabel(RegExp('^Home'))));
    await wait(tester);

    final before = backend.adapter.requests.length;
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await wait(tester);
    await fillInDevAccount(tester);
    await tester.pump();
    await tapVisible(tester, find.widgetWithText(AppButton, 'Sign in'));
    await wait(tester);
    expect(find.text('Trending now'), findsOneWidget);
    final afterLogin = backend.adapter.requests.skip(before).toList();
    // Only Home's own data: two small sections (size 4), no Categories search (size 20).
    expect(afterLogin.where((r) => r.path == '/products').map((r) => r.queryParameters['size']), everyElement(4));
    expect(afterLogin.map((r) => r.path), isNot(contains('/cart')));

    final beforeCategories = backend.adapter.requests.length;
    await tester.tap(find.descendant(of: find.byType(BottomNavBar), matching: find.bySemanticsLabel(RegExp('^Categories'))));
    await wait(tester);
    final search = backend.adapter.requests.skip(beforeCategories).where((r) => r.path == '/products');
    expect(search.map((r) => r.queryParameters['size']), [20]); // re-run now, for the signed-in hearts
  });
}
