import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/widgets/buttons/app_button.dart';
import 'package:frontend_app/widgets/inputs/category_chip.dart';

import '../helpers.dart';

Future<void> openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$tab')));
  await wait(tester);
}

/// Scrolls the page until [finder] is built and clear of the floating tab bar, then taps it.
Future<void> tapAboveTabBar(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(finder, find.byType(Scrollable).first, const Offset(0, -200));
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
  await tester.pump();
  await tester.tap(finder);
}

Finder tile(String title) => find.bySemanticsLabel(RegExp('^${RegExp.escape(title)}'));

void main() {
  testWidgets('wishlist: newest first, remove with undo, add all in stock', (tester) async {
    await startSignedIn(tester);
    await openTab(tester, 'Wishlist');
    expect(find.text('2 saved'), findsOneWidget);
    final sunglasses = tester.getTopLeft(find.text('Classic Sunglasses')).dy;
    final sneakers = tester.getTopLeft(find.text('Cloud Sneakers')).dy;
    expect(sunglasses, lessThan(sneakers)); // saved last, shown first

    await tester.tap(find.byTooltip('Remove Classic Sunglasses from wishlist'));
    await tester.pump();
    expect(find.text('1 saved'), findsOneWidget);
    await wait(tester, steps: 2);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(find.text('2 saved'), findsOneWidget);

    await tapAboveTabBar(tester, find.text('Add all in stock to cart (2)'));
    await wait(tester, steps: 4); // the Undo toast animates out first
    expect(find.text('Added 2 items to cart'), findsOneWidget);
  });

  testWidgets('notifications: groups, filters, mark read, clear with undo', (tester) async {
    await startSignedIn(tester);
    await tester.tap(find.byTooltip('Notifications, 2 unread'));
    await wait(tester);
    expect(find.text('2 unread'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('EARLIER'), findsOneWidget);

    await tester.tap(find.text('Mark as read').first);
    await tester.pump();
    expect(find.text('1 unread'), findsOneWidget);

    await tester.tap(find.byTooltip('Mark all as read'));
    await tester.pump();
    expect(find.text('All caught up'), findsOneWidget);
    await tester.tap(find.widgetWithText(CategoryChip, 'Unread'));
    await tester.pump();
    expect(find.text('You’re all caught up'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Show all'));
    await tester.pump();
    await tapAboveTabBar(tester, find.text('Clear all notifications'));
    await tester.pump();
    expect(find.text('No notifications'), findsOneWidget);
    await wait(tester, steps: 2);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(find.text('TODAY'), findsOneWidget);
  });

  testWidgets('tapping an order notification marks it read and opens that order', (tester) async {
    await startSignedIn(tester);
    await tester.tap(find.byTooltip('Notifications, 2 unread'));
    await wait(tester);
    await tester.tap(tile('Your order is on the way'));
    await wait(tester);
    expect(find.text('#MC-19842'), findsOneWidget);
    expect(find.text('Order status'), findsOneWidget);
  });

  testWidgets('profile: edit with validation, then discard confirmation', (tester) async {
    await startSignedIn(tester);
    await openTab(tester, 'Profile');
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('Member since 2026'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await wait(tester, steps: 2);
    final save = find.widgetWithText(AppButton, 'Save changes');
    expect(tester.widget<AppButton>(save).onPressed, isNull); // nothing changed yet

    await tester.enterText(find.byType(TextField).at(0), '  ');
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    expect(find.text('Enter your full name.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Alex Kim');
    await tester.tap(save);
    await wait(tester, steps: 3);
    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.text('Alex Kim'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await wait(tester, steps: 2);
    await tester.enterText(find.byType(TextField).at(2), '+855 99 000 111');
    await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
    await wait(tester, steps: 2);
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await wait(tester, steps: 3);
    expect(find.text('Edit profile'), findsNothing);
    expect(find.text('+855 99 000 111'), findsNothing);
  });

  testWidgets('deferred items are marked Soon', (tester) async {
    await startSignedIn(tester);
    await openTab(tester, 'Profile');
    await tester.dragUntilVisible(find.text('Contact us'), find.byType(Scrollable).first, const Offset(0, -200));
    expect(find.text('Soon'), findsNWidgets(3)); // Settings, About, Contact
  });

  testWidgets('log out asks first, then returns to sign in', (tester) async {
    await startSignedIn(tester);
    await openTab(tester, 'Profile');
    await tapAboveTabBar(tester, find.widgetWithText(AppButton, 'Log out'));
    await wait(tester, steps: 2);
    expect(find.text('Log out of APM?'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Log out').last);
    await wait(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('reset demo data keeps you signed in and leaves the server cart alone', (tester) async {
    await startSignedIn(tester);
    await openTab(tester, 'Cart');
    await tester.tap(find.byTooltip('Remove Minimal Watch from cart'));
    await wait(tester, steps: 2);
    expect(find.text('2 items'), findsOneWidget);

    await openTab(tester, 'Profile');
    await tapAboveTabBar(tester, find.text('Reset demo data'));
    await wait(tester, steps: 2);
    await tester.tap(find.widgetWithText(AppButton, 'Reset'));
    await wait(tester, steps: 4);
    expect(find.text('Demo data restored'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing); // still signed in; the account is on the server

    await openTab(tester, 'Cart');
    expect(find.text('2 items'), findsOneWidget); // the cart is real data now, not demo data
  });
}
