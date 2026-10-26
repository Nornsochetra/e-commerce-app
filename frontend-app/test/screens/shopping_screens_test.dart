import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/widgets/buttons/app_button.dart';
import 'package:frontend_app/widgets/inputs/category_chip.dart';
import 'package:frontend_app/widgets/layout/bottom_nav_bar.dart';
import 'package:frontend_app/widgets/inputs/search_bar.dart';

import '../helpers.dart';

Finder richText(String text) => find.textContaining(text, findRichText: true);

void main() {
  testWidgets('home as a guest: greeting without a name, carousel, no order banner; a category chip opens that category', (tester) async {
    await startAsGuest(tester);
    expect(find.text('What are you shopping for today?'), findsOneWidget);
    expect(find.textContaining(', Alex'), findsNothing);
    expect(find.text('Shop footwear'), findsOneWidget);
    expect(find.textContaining('Order #'), findsNothing);
    expect(find.text('Trending now'), findsOneWidget);
    expect(find.byTooltip(RegExp('^Notifications')), findsNothing); // guests get Sign in instead of the bell
    expect(find.widgetWithText(AppButton, 'Sign in'), findsOneWidget);

    await tapVisible(tester, find.widgetWithText(CategoryChip, 'Bags'));
    await wait(tester);
    expect(richText('1 product'), findsOneWidget);
    expect(find.text('Canvas Backpack'), findsOneWidget);
    expect(find.text('Minimal Watch'), findsNothing);
  });

  testWidgets('search: no results state, clear, then a name match', (tester) async {
    await startAsGuest(tester);
    await tester.tap(find.byType(AppSearchBar));
    await wait(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No products found'), findsOneWidget);
    expect(find.textContaining('Nothing matches “zzz”'), findsOneWidget);

    await tapVisible(tester, find.text('Clear search & filters'));
    await wait(tester, steps: 2);
    expect(richText('6 products'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'watch');
    await tester.pump();
    expect(richText('1 product for “watch”'), findsOneWidget);
    expect(find.text('Minimal Watch'), findsOneWidget);
  });

  testWidgets('filter sheet from Home: in stock only updates the count and the results', (tester) async {
    await startAsGuest(tester);
    await tester.tap(find.byTooltip('Filter products'));
    await wait(tester);
    expect(find.text('Filter & sort'), findsOneWidget);
    expect(find.text('Show 6 products'), findsOneWidget);

    await tapVisible(tester, find.text('In stock only'));
    await tester.pump();
    expect(find.text('Show 5 products'), findsOneWidget);

    await tester.tap(find.text('Show 5 products'));
    await wait(tester, steps: 3);
    expect(find.text('Filter & sort'), findsNothing);
    expect(richText('5 products · in stock'), findsOneWidget);
    expect(find.byTooltip('Filter and sort, options on'), findsOneWidget);
  });

  testWidgets('guest Home: no cart badge or saved hearts; Sign in brings them back', (tester) async {
    Finder cartBadge(String n) => find.descendant(of: find.byType(BottomNavBar), matching: find.text(n));
    await startAsGuest(tester);
    expect(cartBadge('3'), findsNothing); // the demo cart belongs to the account, not to guests
    expect(find.byTooltip('Remove Cloud Sneakers from wishlist'), findsNothing);
    expect(find.byTooltip('Save Cloud Sneakers to wishlist'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await wait(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget); // new users can sign up from here

    await tester.tap(find.text('Fill in'));
    await tester.pump();
    await tapVisible(tester, find.widgetWithText(AppButton, 'Sign in'));
    await wait(tester);
    expect(find.text('Trending now'), findsOneWidget);
    expect(find.byTooltip(RegExp('^Notifications')), findsOneWidget); // signed in: the bell is back
    expect(cartBadge('3'), findsOneWidget);
    expect(find.byTooltip('Remove Cloud Sneakers from wishlist'), findsOneWidget);
  });

  testWidgets('product details: stock, quantity and price; guests must sign in to add', (tester) async {
    await startAsGuest(tester);
    await tapVisible(tester, find.bySemanticsLabel('View Minimal Watch').first);
    await wait(tester);
    expect(find.text('Minimal Watch'), findsOneWidget);
    expect(find.text('In stock'), findsOneWidget);
    expect(find.text('Add to cart · \$89.00'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity of Minimal Watch'));
    await tester.pump();
    expect(find.text('Add to cart · \$178.00'), findsOneWidget);

    await tester.tap(find.text('Add to cart · \$178.00'));
    await wait(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('sold-out product offers Save for later instead of Add to cart', (tester) async {
    await startAsGuest(tester);
    await tapVisible(tester, find.widgetWithText(CategoryChip, 'Electronics'));
    await wait(tester);
    await tapVisible(tester, find.bySemanticsLabel('View Studio Headphones'));
    await wait(tester);
    expect(find.text('Save for later'), findsOneWidget);
    expect(find.text('Out of stock'), findsWidgets);
    expect(find.textContaining('Add to cart'), findsNothing);
  });

  testWidgets('signed in: greeting with name, order update, and "already in your cart" on details', (tester) async {
    await startSignedIn(tester);
    expect(find.textContaining(', Alex'), findsOneWidget);
    expect(find.text('Order #MC-19842'), findsOneWidget);
    expect(find.text('On the way to you'), findsOneWidget);

    await tapVisible(tester, find.bySemanticsLabel('View Minimal Watch').first);
    await wait(tester);
    expect(richText('1 already in your cart'), findsOneWidget);

    await tester.tap(find.text('Add to cart · \$89.00'));
    await wait(tester, steps: 2);
    expect(find.text('Cart quantity updated'), findsOneWidget);
    expect(richText('2 already in your cart'), findsOneWidget);
  });
}
