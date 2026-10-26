import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/models/common/page_result.dart';
import 'package:frontend_app/models/product/product_filter.dart';
import 'package:frontend_app/services/api/api_client.dart';
import 'package:frontend_app/services/api/api_exception.dart';
import 'package:frontend_app/services/api/token_storage.dart';
import 'package:frontend_app/services/auth/auth_service.dart';
import 'package:frontend_app/services/auth/dev_account.dart';
import 'package:frontend_app/services/cart/cart_service.dart';
import 'package:frontend_app/services/health/health_service.dart';
import 'package:frontend_app/services/product/product_service.dart';
import 'package:frontend_app/services/user/user_service.dart';
import 'package:frontend_app/services/wishlist/wishlist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smoke test against a real backend (skipped by default). Start the backend with the dev profile, then:
///   flutter test test/api/live_api_test.dart --dart-define=LIVE_API=true
/// Add --dart-define=API_BASE_URL=… when it isn't at http://localhost:8081/api/v1.
/// Uses the development account seeded by backend/src/main/resources/db/migration/V2__seed_users.sql.
const _live = bool.fromEnvironment('LIVE_API');
const _devEmail = devAccountEmail;
const _devPassword = devAccountPassword;

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

  test('slice C service: categories, server search, filters, sorts, paging and details (read-only)', () async {
    final catalog = ProductService(ApiClient(tokens: MemoryTokenStorage()));
    final categories = await catalog.getCategories();
    expect(categories.map((c) => c.slug), containsAll(['accessories', 'footwear', 'bags', 'electronics']));
    final electronics = categories.firstWhere((c) => c.slug == 'electronics');

    final all = await catalog.getProducts(size: 100);
    final watch = all.items.firstWhere((p) => p.name == 'Minimal Watch');
    expect(watch.price, 89.0);
    expect(watch.badges, containsAll(['NEW', 'PREMIUM_PICK']));
    expect(watch.description, isNull); // lists leave it out

    expect((await catalog.getProducts(query: 'WATCH')).items.map((p) => p.name), contains('Minimal Watch'));
    final inElectronics = await catalog.getProducts(categoryId: electronics.id);
    expect(inElectronics.items.every((p) => p.categoryId == electronics.id), isTrue);
    final inStockElectronics = await catalog.getProducts(categoryId: electronics.id, inStockOnly: true);
    expect(inStockElectronics.items.every((p) => p.inStock), isTrue);
    expect(inStockElectronics.items.map((p) => p.name), isNot(contains('Studio Headphones')));

    for (final sort in ProductSort.values) {
      final prices = (await catalog.getProducts(sort: sort, size: 100)).items.map((p) => p.price).toList();
      if (sort == ProductSort.priceLow) expect(prices, [...prices]..sort());
      if (sort == ProductSort.priceHigh) expect(prices, [...prices]..sort((a, b) => b.compareTo(a)));
    }

    final first = await catalog.getProducts(size: 4);
    expect(first.items, hasLength(4));
    expect(first.hasNext, all.totalElements > 4);
    final second = await catalog.getProducts(page: 1, size: 4);
    expect(second.items.map((p) => p.id).toSet().intersection(first.items.map((p) => p.id).toSet()), isEmpty);

    final detail = await catalog.getProduct(watch.id);
    expect(detail.description, isNotNull);
    await expectLater(
      catalog.getProduct('00000000-0000-4000-8000-000000000000'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'PRODUCT_NOT_FOUND')),
    );
  }, skip: !_live);

  test('slice D services: cart and wishlist on the server (leaves both as it found them)', () async {
    final client = ApiClient(tokens: MemoryTokenStorage());
    final login = await client.post('/auth/login', body: {'email': _devEmail, 'password': _devPassword}, auth: false) as Map<String, dynamic>;
    await client.tokens.save(TokenPair.fromJson(login));
    final carts = CartService(client);
    final wishlists = WishlistService(client);
    final products = (await ProductService(client).getProducts(size: 100)).items;

    // Cart: use an in-stock product that isn't in the cart yet.
    final before = await carts.getCart();
    final p = products.firstWhere((p) => p.availableQuantity >= 2 && !before.items.any((i) => i.productId == p.id));
    var cart = await carts.addItem(p.id, 1);
    final line = cart.items.firstWhere((i) => i.productId == p.id);
    expect(line.id, isNot(p.id)); // cart lines have their own id
    expect(cart.itemCount, before.itemCount + 1);
    cart = await carts.updateItem(line.id, 2);
    expect(cart.items.firstWhere((i) => i.id == line.id).lineTotal, p.price * 2); // calculated by the server
    await expectLater(carts.updateItem(line.id, p.availableQuantity + 1), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'INSUFFICIENT_STOCK')));
    final soldOut = products.where((p) => p.availableQuantity == 0).firstOrNull;
    if (soldOut != null) {
      await expectLater(carts.addItem(soldOut.id, 1), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'PRODUCT_OUT_OF_STOCK')));
    }
    cart = await carts.removeItem(line.id);
    expect(cart.itemCount, before.itemCount); // back to how it was

    // Wishlist: use a product that isn't saved yet.
    final saved = (await wishlists.getPage(0)).items.map((p) => p.id).toSet();
    final w = products.firstWhere((p) => !saved.contains(p.id));
    expect((await wishlists.save(w.id)).id, w.id);
    await wishlists.save(w.id); // saving twice is harmless
    final page = await wishlists.getPage(0);
    expect(page.items.first.id, w.id); // newest first
    expect(page.items.where((p) => p.id == w.id), hasLength(1));
    await wishlists.remove(w.id);
    await expectLater(wishlists.remove(w.id), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'WISHLIST_ITEM_NOT_FOUND')));
    expect((await wishlists.getPage(0)).items.map((p) => p.id).toSet(), saved); // back to how it was
  }, skip: !_live);

  test('slice B services: sign in, load and edit the profile (then restore it), log out everywhere', () async {
    SharedPreferences.setMockInitialValues({});
    final client = ApiClient(tokens: MemoryTokenStorage());
    final auth = AuthService(client);
    final users = UserService(client);

    await auth.login(_devEmail, _devPassword);
    expect(await auth.getSession(), SessionType.signedIn);
    final original = await users.getUser();
    expect(original.email, _devEmail);

    final edited = await users.updateProfile(name: '${original.name} (test)', email: original.email, phone: original.phone);
    expect(edited.name, '${original.name} (test)');
    final restored = await users.updateProfile(name: original.name, email: original.email, phone: original.phone);
    expect(restored.name, original.name);

    final oldRefresh = (await client.tokens.read())!.refreshToken;
    await auth.logout();
    expect(await auth.getSession(), isNull);
    // Logout revokes every token of the account on the server, so the old refresh token is now useless.
    await expectLater(
      client.post('/auth/refresh', body: {'refreshToken': oldRefresh}, auth: false),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
  }, skip: !_live);
}
