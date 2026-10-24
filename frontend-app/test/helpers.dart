import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/main.dart';
import 'package:frontend_app/providers/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets mock delays (300 ms), the splash (≈2 s) and page transitions finish.
/// (pumpAndSettle can't be used: some animations, like the splash rings, repeat forever.)
Future<void> wait(WidgetTester tester, {int steps = 8}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Test on an iPhone 16-sized screen (393×852) instead of the default 800×600.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Taps a widget after scrolling it into view.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

/// Starts the app with empty storage and waits until the splash has opened Sign in.
Future<void> startAppAtLogin(WidgetTester tester) async {
  usePhoneScreen(tester);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(MercatoApp(authProvider: AuthProvider()));
  await wait(tester, steps: 14);
}
