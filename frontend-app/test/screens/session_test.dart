import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/main.dart';
import 'package:frontend_app/providers/auth/auth_provider.dart';
import 'package:frontend_app/widgets/buttons/app_button.dart';

import '../helpers.dart';

/// Closes the app and opens it again (same device storage and tokens), then waits for the splash.
Future<void> restartApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(ApmApp(authProvider: AuthProvider()));
  await wait(tester, steps: 14);
}

Future<void> openProfile(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^Profile')));
  await wait(tester);
}

/// Opens Edit profile, types [text] into field [index] (0 name, 1 email, 2 phone) and taps Save.
Future<void> editProfileField(WidgetTester tester, int index, String text) async {
  await tester.tap(find.text('Edit'));
  await wait(tester, steps: 2);
  await tester.enterText(find.byType(TextField).at(index), text);
  await tester.pump(); // Save is enabled once the sheet sees the change
  await tester.tap(find.widgetWithText(AppButton, 'Save changes'));
  await wait(tester, steps: 4);
}

Future<void> fillRegister(WidgetTester tester, {required String email, String phone = ''}) async {
  await tapVisible(tester, find.text('Create an account'));
  await wait(tester, steps: 3);
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Sok Dara');
  await tester.enterText(fields.at(1), email);
  await tester.enterText(fields.at(2), phone);
  await tester.enterText(fields.at(3), 'Passw0rd!');
  await tester.enterText(fields.at(4), 'Passw0rd!');
  await tapVisible(tester, find.widgetWithText(TextButton, 'Create account'));
  await wait(tester);
}

void main() {
  testWidgets('create account signs in, saves the phone with a profile update, and shows it on Profile', (tester) async {
    final backend = await startAppAtLogin(tester);
    await fillRegister(tester, email: 'dara@example.com', phone: '+855 11 222 333');
    expect(find.text('Trending now'), findsOneWidget); // Home
    expect(backend.calls('POST', '/auth/register'), 1);
    expect(backend.calls('PATCH', '/me/profile'), 1); // register has no phone field

    await openProfile(tester);
    expect(find.text('Sok Dara'), findsOneWidget);
    expect(find.text('+855 11 222 333'), findsOneWidget);
  });

  testWidgets('create account with an email that is already registered explains why', (tester) async {
    await startAppAtLogin(tester);
    await fillRegister(tester, email: 'user@example.com');
    expect(find.text('An account with this email already exists.'), findsOneWidget);
    expect(find.text('Trending now'), findsNothing);
  });

  testWidgets('a signed-in session survives an app restart; log out ends it on the server too', (tester) async {
    final backend = await startSignedIn(tester);
    await restartApp(tester);
    expect(find.text('Trending now'), findsOneWidget); // straight to Home, no sign-in

    await openProfile(tester);
    expect(find.text('Alex Morgan'), findsOneWidget); // loaded from GET /auth/me
    await tester.dragUntilVisible(find.widgetWithText(AppButton, 'Log out'), find.byType(Scrollable).first, const Offset(0, -200));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'Log out'));
    await wait(tester, steps: 2);
    await tester.tap(find.widgetWithText(AppButton, 'Log out').last);
    await wait(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(backend.calls('POST', '/auth/logout'), 1);
    expect(await backend.tokens.read(), isNull);

    await restartApp(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('an expired access token is refreshed without the user noticing', (tester) async {
    final backend = await startSignedIn(tester);
    await openProfile(tester);
    backend.expireAccessTokens();

    await editProfileField(tester, 0, 'Alex Kim');
    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.text('Alex Kim'), findsOneWidget);
    expect(backend.calls('POST', '/auth/refresh'), 1);
  });

  testWidgets('when the session is revoked, the next request signs out and Sign in says why', (tester) async {
    final backend = await startSignedIn(tester);
    await openProfile(tester);
    backend.revokeAllTokens();

    await editProfileField(tester, 0, 'Alex Kim');
    await wait(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Your session has ended. Please sign in again.'), findsOneWidget);
  });

  testWidgets('profile: an email used by another account is flagged on the email field', (tester) async {
    final backend = await startSignedIn(tester);
    backend.addAccount(name: 'Sam', email: 'sam@example.com');
    await openProfile(tester);

    await editProfileField(tester, 1, 'Sam@Example.com');
    expect(find.text('An account with this email already exists.'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget); // the sheet stays open
  });
}
