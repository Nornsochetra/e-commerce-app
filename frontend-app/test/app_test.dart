import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/main.dart';
import 'package:frontend_app/providers/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets mock delays (300 ms) and page transitions finish. (pumpAndSettle can't be used:
/// loading skeletons and the progress bar animate forever.)
Future<void> wait(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('splash → sign in → guest home; cart asks guests to sign in and returns after', (tester) async {
    await tester.pumpWidget(MercatoApp(authProvider: AuthProvider()));
    expect(find.text('Fresh, simple, delivered.'), findsOneWidget); // splash
    await wait(tester);
    expect(find.text('Welcome back'), findsOneWidget); // login

    await tester.tap(find.text('Continue as guest'));
    await wait(tester);
    expect(find.text('Trending now'), findsOneWidget); // home

    await tester.tap(find.bySemanticsLabel(RegExp('^Cart')));
    await wait(tester);
    expect(find.text('Welcome back'), findsOneWidget); // cart needs sign-in → login

    await tester.tap(find.text('Sign in with demo account'));
    await wait(tester);
    expect(find.text('My Cart'), findsOneWidget); // back to the cart after signing in
    expect(find.text('Minimal Watch'), findsOneWidget);
  });
}
