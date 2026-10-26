import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/main.dart';
import 'package:frontend_app/providers/auth/auth_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Walks through the finished screens on a real simulator and saves screenshots for review.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester tester, [int ms = 1200]) async {
    for (var t = 0; t < ms; t += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  testWidgets('slice 2: splash and sign-in screens', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await tester.pumpWidget(MercatoApp(authProvider: AuthProvider()));
    await wait(tester, 1100);
    await binding.takeScreenshot('s2_01_splash');
    await wait(tester, 2200);
    await binding.takeScreenshot('s2_02_login');

    await tap(tester, find.text('Sign in'));
    await wait(tester, 300);
    await binding.takeScreenshot('s2_03_login_errors');

    await tap(tester, find.text('Fill in'));
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass1');
    await tap(tester, find.text('Sign in'));
    await wait(tester, 800);
    await binding.takeScreenshot('s2_04_login_wrong_password');

    await tap(tester, find.text('Create an account'));
    await wait(tester, 800);
    await tester.enterText(find.byType(TextField).at(0), 'Sok Dara');
    await tester.enterText(find.byType(TextField).at(1), 'dara@example');
    await tester.enterText(find.byType(TextField).at(3), 'Passw0rd');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await wait(tester, 300);
    await binding.takeScreenshot('s2_05_register');
    await tap(tester, find.widgetWithText(TextButton, 'Create account'));
    await wait(tester, 300);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await wait(tester, 400);
    await binding.takeScreenshot('s2_06_register_errors');

    await tap(tester, find.byTooltip('Back to sign in'));
    await wait(tester, 800);
    await tap(tester, find.text('Forgot password?'));
    await wait(tester, 800);
    await binding.takeScreenshot('s2_07_forgot');
    await tester.enterText(find.byType(TextField), 'someone@example.com');
    await tap(tester, find.text('Send instructions'));
    await wait(tester, 900);
    await binding.takeScreenshot('s2_08_forgot_sent');
  });

  testWidgets('slice 3: home, categories and product details', (tester) async {
    await (await SharedPreferences.getInstance()).clear();
    await tester.pumpWidget(MercatoApp(authProvider: AuthProvider()));
    await wait(tester, 3300);
    await tap(tester, find.text('Fill in'));
    await tap(tester, find.text('Sign in'));
    await wait(tester, 2500); // product photos load from the network
    await binding.takeScreenshot('s3_01_home');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -520));
    await wait(tester, 1500);
    await binding.takeScreenshot('s3_02_home_trending');

    await tap(tester, find.byTooltip('Filter products'));
    await wait(tester, 2000);
    await binding.takeScreenshot('s3_03_categories_filter_sheet');
    await tap(tester, find.text('In stock only'));
    await wait(tester, 300);
    await tap(tester, find.textContaining('Show '));
    await wait(tester, 800);
    await binding.takeScreenshot('s3_04_categories_filtered');

    await tester.enterText(find.byType(TextField), 'zzz');
    await wait(tester, 400);
    await binding.takeScreenshot('s3_05_no_results');
    await tap(tester, find.text('Clear search & filters'));
    await wait(tester, 800);

    await tap(tester, find.bySemanticsLabel('View Minimal Watch'));
    await wait(tester, 1500);
    await binding.takeScreenshot('s3_06_product');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await wait(tester, 1000);
    await binding.takeScreenshot('s3_07_product_more');

    await tap(tester, find.byTooltip('Back'));
    await wait(tester, 800);
    await tap(tester, find.textContaining('Electronics'));
    await wait(tester, 800);
    await tap(tester, find.bySemanticsLabel('View Studio Headphones'));
    await wait(tester, 1500);
    await binding.takeScreenshot('s3_08_product_sold_out');
  });
}
