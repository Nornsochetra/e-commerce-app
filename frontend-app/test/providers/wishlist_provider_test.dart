import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/providers/auth/auth_provider.dart';
import 'package:frontend_app/providers/wishlist/wishlist_provider.dart';
import 'package:frontend_app/services/api/api_client.dart';

import '../fake_api.dart';
import '../fake_catalog.dart';

void main() {
  late FakeBackend backend;
  late WishlistProvider wishlist;
  final sneakers = mockProducts[1];
  final sunglasses = mockProducts[4];
  final camera = mockProducts[5];

  setUp(() async {
    backend = FakeBackend();
    ApiClient.instance = backend.client;
    await backend.signIn();
    wishlist = WishlistProvider()..syncWith(AuthStatus.signedIn);
  });

  test('nothing loads until the Wishlist screen asks; then the first page, newest first', () async {
    expect(backend.calls('GET', '/wishlist/items'), 0);
    await wishlist.ensureLoaded();
    expect(wishlist.items.map((p) => p.name), ['Classic Sunglasses', 'Cloud Sneakers']);
    expect(wishlist.total, 2);
    expect(backend.adapter.requests.last.queryParameters['size'], 20);
    await wishlist.ensureLoaded(); // already loaded
    expect(backend.calls('GET', '/wishlist/items'), 1);
  });

  test('hearts come from the product’s saved flag; a heart tapped this session wins', () async {
    expect(wishlist.isSaved(camera), isFalse); // camera.saved is false
    expect(await wishlist.toggle(camera), isNull);
    expect(wishlist.isSaved(camera), isTrue);
    expect(await wishlist.toggle(camera), isNull);
    expect(wishlist.isSaved(camera), isFalse);
    expect(backend.calls('GET', '/wishlist/items'), 0); // no wishlist download needed for hearts
  });

  test('save tells newly saved from already saved; unsave then Undo saves again', () async {
    await wishlist.ensureLoaded();
    final (error, isNew) = await wishlist.save(camera.id);
    expect(error, isNull);
    expect(isNew, isTrue);
    expect(wishlist.items.first.name, 'Everyday Camera');
    expect(wishlist.total, 3);
    expect((await wishlist.save(sneakers.id)).$2, isFalse); // already saved
    expect(wishlist.total, 3);

    expect(await wishlist.unsave(sunglasses.id), isNull);
    expect(wishlist.total, 2);
    expect(wishlist.items.map((p) => p.name), isNot(contains('Classic Sunglasses')));
    await wishlist.save(sunglasses.id); // Undo
    expect(wishlist.items.first.name, 'Classic Sunglasses');
  });

  test('when the server can’t be reached, the heart goes back and the reason is returned', () async {
    backend.offline = true;
    expect(await wishlist.toggle(camera), contains('Can’t reach APM'));
    expect(wishlist.isSaved(camera), isFalse);
  });

  test('signing out forgets the wishlist and the tapped hearts', () async {
    await wishlist.ensureLoaded();
    await wishlist.toggle(camera);
    wishlist.syncWith(AuthStatus.signedOut);
    await Future<void>.delayed(Duration.zero);
    expect(wishlist.items, isEmpty);
    expect(wishlist.isSaved(camera), isFalse);
  });
}
