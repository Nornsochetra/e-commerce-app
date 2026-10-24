import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/utils/formatters.dart';
import 'package:frontend_app/utils/validators.dart';

void main() {
  test('email validation', () {
    expect(validateEmail(''), 'Enter your email address.');
    expect(validateEmail('bad'), isNotNull);
    expect(validateEmail('you@example.com'), isNull);
  });

  test('password must be 8–72 characters', () {
    expect(validatePassword('short'), isNotNull);
    expect(validatePassword('Demo123!'), isNull);
    expect(validatePassword('a' * 73), isNotNull);
  });

  test('phone is optional but must look like a phone number', () {
    expect(validatePhone(''), isNull);
    expect(validatePhone('+855 12 345 678'), isNull);
    expect(validatePhone('abc'), isNotNull);
  });

  test('formatters', () {
    expect(formatMoney(89), r'$89.00');
    expect(formatLabel('PREMIUM_PICK'), 'Premium Pick');
    final now = DateTime(2026, 10, 24, 12);
    expect(timeAgo(now.subtract(const Duration(hours: 2)), now: now), '2 hours ago');
    expect(timeAgo(now.subtract(const Duration(days: 1)), now: now), 'Yesterday');
  });
}
