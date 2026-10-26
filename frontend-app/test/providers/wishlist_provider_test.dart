import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/data/mock_data.dart';
import 'package:frontend_app/providers/wishlist/wishlist_provider.dart';
import 'package:frontend_app/services/api/api_client.dart';

import '../fake_api.dart';

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
    wishlist = WishlistProvider();
    await wishlist.load();
  });

  test('loads saved products from the server, newest first', () {
    expect(wishlist.items.map((p) => p.name), ['Classic Sunglasses', 'Cloud Sneakers']);
    expect(wishlist.contains(sneakers.id), isTrue);
    expect(wishlist.count, 2);
  });

  test('toggle saves (newest first) and un-saves on the server', () async {
    expect(await wishlist.toggle(camera), isNull);
    expect(wishlist.items.first.name, 'Everyday Camera');
    expect(backend.calls('POST', '/wishlist/items'), 1);

    expect(await wishlist.toggle(camera), isNull);
    expect(wishlist.contains(camera.id), isFalse);

    final reloaded = WishlistProvider();
    await reloaded.load();
    expect(reloaded.items.map((p) => p.name), ['Classic Sunglasses', 'Cloud Sneakers']);
  });

  test('remove returns the product so Undo can save it again', () async {
    final removed = await wishlist.remove(sunglasses.id);
    expect(removed?.name, 'Classic Sunglasses');
    expect(wishlist.count, 1);
    expect(await wishlist.save(removed!.id, optimistic: removed), isNull);
    expect(wishlist.items.first.name, 'Classic Sunglasses');
  });

  test('when the server can’t be reached, the heart goes back and the reason is returned', () async {
    backend.offline = true;
    final error = await wishlist.toggle(camera);
    expect(error, contains('Can’t reach APM'));
    expect(wishlist.contains(camera.id), isFalse);
    expect(await wishlist.toggle(sneakers), contains('Can’t reach APM'));
    expect(wishlist.contains(sneakers.id), isTrue); // un-saving was undone too
  });
}
