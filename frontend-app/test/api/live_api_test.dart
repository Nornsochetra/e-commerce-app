import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/models/common/page_result.dart';
import 'package:frontend_app/services/api/api_client.dart';
import 'package:frontend_app/services/api/api_exception.dart';
import 'package:frontend_app/services/api/token_storage.dart';
import 'package:frontend_app/services/health/health_service.dart';

/// Smoke test against a real backend (skipped by default). Start the backend with the dev profile, then:
///   flutter test test/api/live_api_test.dart --dart-define=LIVE_API=true
/// Add --dart-define=API_BASE_URL=… when it isn't at http://localhost:8081/api/v1.
/// Uses the development account seeded by backend/src/main/resources/db/migration/V2__seed_users.sql.
const _live = bool.fromEnvironment('LIVE_API');
const _devEmail = 'user@example.com';
const _devPassword = 'Demo123!';

void main() {
  final tokens = MemoryTokenStorage();
  final api = ApiClient(tokens: tokens);

  test('health reports UP', () async {
    expect(await HealthService(api).isAvailable(), isTrue);
  }, skip: !_live);

  test('the dev catalog seed is loaded (public read)', () async {
    final page = PageResult.fromJson(await api.get('/products', auth: false) as Map<String, dynamic>, (json) => json['name'] as String);
    expect(page.items, containsAll(['Minimal Watch', 'Cloud Sneakers', 'Canvas Backpack', 'Studio Headphones', 'Classic Sunglasses', 'Everyday Camera']));
  }, skip: !_live);

  test('wrong password is INVALID_CREDENTIALS', () async {
    await expectLater(
      api.post('/auth/login', body: {'email': _devEmail, 'password': 'wrong-password'}, auth: false),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'INVALID_CREDENTIALS')),
    );
  }, skip: !_live);

  test('sign in, read /auth/me, and survive an expired access token via refresh', () async {
    final login = await api.post('/auth/login', body: {'email': _devEmail, 'password': _devPassword}, auth: false) as Map<String, dynamic>;
    await tokens.save(TokenPair.fromJson(login));

    final me = await api.get('/auth/me') as Map<String, dynamic>;
    expect(me['email'], _devEmail);

    // Pretend the access token expired: the client must refresh and retry by itself.
    final current = (await tokens.read())!;
    await tokens.save(TokenPair(accessToken: 'expired-or-broken', refreshToken: current.refreshToken));
    final again = await api.get('/auth/me') as Map<String, dynamic>;
    expect(again['email'], _devEmail);
    expect((await tokens.read())!.accessToken, isNot('expired-or-broken'));
  }, skip: !_live);
}
