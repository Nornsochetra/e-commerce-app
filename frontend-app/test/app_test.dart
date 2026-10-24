import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('splash → sign in → guest home; cart asks guests to sign in and returns after', (tester) async {
    await startAppAtLogin(tester);
    expect(find.text('Welcome back'), findsOneWidget);

    await tapVisible(tester, find.text('Continue as guest'));
    await wait(tester);
    expect(find.text('Trending now'), findsOneWidget); // home

    await tester.tap(find.bySemanticsLabel(RegExp('^Cart')));
    await wait(tester);
    expect(find.text('Welcome back'), findsOneWidget); // cart needs sign-in → login

    await tester.tap(find.text('Fill in'));
    await tester.pump();
    await tapVisible(tester, find.text('Sign in'));
    await wait(tester);
    expect(find.text('My Cart'), findsOneWidget); // back to the cart after signing in
    expect(find.text('Minimal Watch'), findsOneWidget);
  });
}
