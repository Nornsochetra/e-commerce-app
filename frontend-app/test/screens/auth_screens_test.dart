import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('splash shows the brand and tagline, then opens sign in', (tester) async {
    await startAppAtLogin(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('sign in: empty form shows both errors; wrong password shows a message', (tester) async {
    await startAppAtLogin(tester);
    await tapVisible(tester, find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass1');
    await tapVisible(tester, find.text('Sign in'));
    await wait(tester, steps: 3);
    expect(find.textContaining('don’t match'), findsOneWidget);
  });

  testWidgets('password show/hide toggle', (tester) async {
    await startAppAtLogin(tester);
    TextField password() => tester.widget<TextField>(find.byType(TextField).at(1));
    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('create account: mismatched passwords, then success opens Home', (tester) async {
    await startAppAtLogin(tester);
    await tapVisible(tester, find.text('Create an account'));
    await wait(tester, steps: 3);
    expect(find.text('Create account'), findsWidgets);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Sok Dara');
    await tester.enterText(fields.at(1), 'dara@example.com');
    await tester.enterText(fields.at(3), 'Passw0rd!');
    await tester.enterText(fields.at(4), 'Different1');
    await tester.pump();
    expect(find.textContaining('Strength:'), findsOneWidget);

    await tapVisible(tester, find.widgetWithText(TextButton, 'Create account'));
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);

    await tester.enterText(fields.at(4), 'Passw0rd!');
    await tapVisible(tester, find.widgetWithText(TextButton, 'Create account'));
    await wait(tester);
    expect(find.text('Trending now'), findsOneWidget);
  });
}
