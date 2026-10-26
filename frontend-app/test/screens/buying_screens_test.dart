import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/widgets/inputs/category_chip.dart';

import '../helpers.dart';

Future<void> openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$tab')));
  await wait(tester);
}

void main() {
  testWidgets('cart: totals, quantity, remove with undo', (tester) async {
    await startSignedIn(tester);
    await openTab(tester, 'Cart');
    expect(find.text('3 items'), findsOneWidget); // 1 watch + 2 backpacks
    expect(find.text('\$209.00'), findsWidgets); // 89 + 116 + 4 delivery

    await tester.tap(find.byTooltip('Increase quantity of Minimal Watch'));
    await tester.pump();
    expect(find.text('4 items'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Minimal Watch from cart'));
    await tester.pump();
    expect(find.text('Removed from cart'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);

    await wait(tester, steps: 2); // let the toast slide in
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(find.text('4 items'), findsOneWidget);
  });

  testWidgets('cart: an item at its stock limit says so; save for later moves the other to the wishlist', (tester) async {
    await startSignedIn(tester);
    await openTab(tester, 'Cart');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Increase quantity of Canvas Backpack'));
      await tester.pump();
    }
    expect(find.text('Only 5 available'), findsOneWidget); // 5 = all the stock

    await tester.tap(find.text('Save for later')); // only the watch still offers it
    await tester.pump();
    expect(find.text('Moved to wishlist'), findsOneWidget);
    expect(find.text('Minimal Watch'), findsNothing);
  });

  testWidgets('empty cart shows a way back to shopping', (tester) async {
    await startSignedIn(tester);
    await openTab(tester, 'Cart');
    await tester.tap(find.byTooltip('Remove Minimal Watch from cart'));
    await tester.pump();
    await tester.tap(find.byTooltip('Remove Canvas Backpack from cart'));
    await wait(tester, steps: 2);
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Start shopping'), findsOneWidget);
  });

  testWidgets('checkout: validation, place order, confirmation, then track the order', (tester) async {
    await startSignedIn(tester);
    await openTab(tester, 'Cart');
    await tester.tap(find.text('Checkout'));
    await wait(tester);
    expect(find.text('Alex Morgan'), findsOneWidget); // prefilled delivery card
    expect(find.text('Cash on delivery'), findsOneWidget);
    expect(find.text('Soon'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), '');
    await tester.tap(find.text('Place order'));
    await tester.pump();
    expect(find.text('Enter the recipient’s name.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Sok Dara');
    await tester.tap(find.text('Place order'));
    await tester.pump();
    expect(find.text('Placing…'), findsOneWidget);
    await wait(tester);
    expect(find.text('Order confirmed!'), findsOneWidget);
    expect(find.textContaining('Thanks, Sok.'), findsOneWidget);
    expect(find.text('Estimated delivery'), findsOneWidget);

    await tapVisible(tester, find.text('Track order'));
    await wait(tester);
    expect(find.text('Order status'), findsOneWidget);
    expect(find.textContaining('est.'), findsOneWidget); // the current step shows the delivery window
    expect(find.text('Sok Dara'), findsOneWidget);
    expect(find.text('Minimal Watch'), findsOneWidget);

    await openTab(tester, 'Cart');
    expect(find.text('Your cart is empty'), findsOneWidget); // cleared after ordering
  });

  testWidgets('my orders: filter chips, then open an order', (tester) async {
    await startSignedIn(tester);
    await openTab(tester, 'Profile');
    await tapVisible(tester, find.text('My orders'));
    await wait(tester);
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Order MC-19842')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Order MC-20481')), findsOneWidget);

    await tapVisible(tester, find.widgetWithText(CategoryChip, 'Delivered'));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('^Order MC-19842')), findsNothing);

    await tester.tap(find.bySemanticsLabel(RegExp('^Order MC-20481')));
    await wait(tester);
    expect(find.text('#MC-20481'), findsOneWidget);
    expect(find.text('ITEMS · 3'), findsOneWidget);
    expect(find.textContaining('est.'), findsNothing); // delivered: no estimate
  });
}
