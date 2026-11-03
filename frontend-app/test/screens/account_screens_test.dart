import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/services/auth/dev_account.dart';
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
    await wait(tester, steps: 1); // Undo saves it again on the server
    expect(find.text('2 saved'), findsOneWidget);

    await tapAboveTabBar(tester, find.text('Add all in stock to cart (2)'));
    await wait(tester, steps: 4); // the Undo toast animates out first
    expect(find.text('Added 2 items to cart'), findsOneWidget);
  });

  testWidgets('notifications: groups, filters, mark read, clear all after confirming', (tester) async {
    await startSignedIn(tester);
    await tester.tap(find.byTooltip('Notifications, 2 unread'));
    await wait(tester);
    expect(find.text('2 unread'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('EARLIER'), findsOneWidget);

    await tester.tap(find.text('Mark as read').first);
    await tester.pump();
    expect(find.text('1 unread'), findsOneWidget); // changes at once, saved in the background

    await tester.tap(find.byTooltip('Mark all as read'));
    await wait(tester, steps: 1);
    expect(find.text('All caught up'), findsOneWidget);
    await tester.tap(find.widgetWithText(CategoryChip, 'Unread'));
    await tester.pump();
    expect(find.text('You’re all caught up'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Show all'));
    await tester.pump();
    await tapAboveTabBar(tester, find.text('Clear all notifications'));
    await wait(tester, steps: 2);
    expect(find.text('Clear all notifications?'), findsOneWidget); // the server can't undo it, so it asks first
    await tester.tap(find.widgetWithText(AppButton, 'Clear all'));
    await wait(tester, steps: 2);
    expect(find.text('No notifications'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
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

  testWidgets('change password: checks the fields, rejects a wrong current password, then stays signed in', (tester) async {
    await startSignedIn(tester);
    await openTab(tester, 'Profile');
    await tapAboveTabBar(tester, find.text('Change password'));
    await wait(tester, steps: 2);
    final fields = find.byType(TextField);
    final save = find.widgetWithText(AppButton, 'Change password');

    await tester.enterText(fields.at(0), 'not-my-password');
    await tester.enterText(fields.at(1), 'NewPassw0rd!');
    await tester.enterText(fields.at(2), 'Different1!');
    await tester.tap(save);
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);

    await tester.enterText(fields.at(2), 'NewPassw0rd!');
    await tester.tap(save);
    await wait(tester, steps: 3);
    expect(find.text('Your current password isn’t right.'), findsOneWidget);

    // After the error the field can still be cleared. No autofill hints means no browser form whose
    // password manager could refill the fields (on the web).
    await tester.enterText(fields.at(0), '');
    await tester.pump();
    expect(tester.widget<TextField>(fields.at(0)).controller!.text, isEmpty);
    expect(find.text('Enter your current password.'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(tester.widget<TextField>(fields.at(i)).autofillHints, isNull);
    }

    await tester.enterText(fields.at(0), devAccountPassword);
    await tester.tap(save);
    await wait(tester, steps: 3);
    expect(find.text('Password changed'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Change password'), findsNothing); // the sheet closed

    // The old tokens were revoked; the new pair keeps this device signed in.
    await openTab(tester, 'Cart');
    expect(find.text('Minimal Watch'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
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
}
