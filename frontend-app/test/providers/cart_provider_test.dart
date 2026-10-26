import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/models/order/checkout.dart' show standardDeliveryFeeUsd;
import 'package:frontend_app/providers/auth/auth_provider.dart';
import 'package:frontend_app/providers/cart/cart_provider.dart';
import 'package:frontend_app/services/api/api_client.dart';

import '../fake_catalog.dart';
import '../fake_api.dart';

void main() {
  late FakeBackend backend;
  late CartProvider cart;
  final watch = mockProducts[0]; // 8 in stock
  final backpack = mockProducts[2]; // 5 in stock
  final headphones = mockProducts[3]; // sold out
  final camera = mockProducts[5]; // 3 in stock

  setUp(() async {
    backend = FakeBackend();
    ApiClient.instance = backend.client;
    await backend.signIn();
    cart = CartProvider();
    await cart.load();
  });

  test('loads the server cart; the server calculates the totals', () {
    expect(cart.itemCount, 3); // 1 watch + 2 backpacks
    expect(cart.subtotal, 89 + 2 * 58);
    expect(cart.total, cart.subtotal + standardDeliveryFeeUsd); // delivery is only an estimate here
    expect(cart.items.first.id, isNot(cart.items.first.productId)); // cart lines have their own id
  });

  test('adding: new line, more of the same, and the server stock limits', () async {
    expect(await cart.add(camera, quantity: 2), AddToCartResult.added);
    expect(await cart.add(camera, quantity: 5), AddToCartResult.maxReached); // 7 > 3 in stock
    expect(cart.quantityOf(camera.id), 2); // unchanged
    expect(await cart.add(camera), AddToCartResult.updated);
    expect(cart.quantityOf(camera.id), 3);
    expect(await cart.add(headphones), AddToCartResult.outOfStock);
    expect(cart.lastError, 'This product is out of stock.');
  });

  test('quantity changes are checked by the server', () async {
    expect(await cart.setQuantity(backpack.id, 5), isNull);
    expect(cart.quantityOf(backpack.id), 5);
    expect(await cart.setQuantity(backpack.id, 6), 'There isn’t enough stock for that quantity.');
    expect(cart.quantityOf(backpack.id), 5);
    expect(backend.calls('PATCH', '/cart/items/ci-backpack'), 2);
  });

  test('remove and undo, and clear empties the server cart', () async {
    final removed = await cart.remove(watch.id);
    expect(removed?.name, 'Minimal Watch');
    expect(cart.itemCount, 2);
    expect(await cart.restore(removed!), isNull);
    expect(cart.itemCount, 3);

    await cart.clear();
    expect(cart.items, isEmpty);
    final reloaded = CartProvider();
    await reloaded.load();
    expect(reloaded.items, isEmpty); // gone on the server too
  });

  test('a failed change keeps the cart as it was and explains why', () async {
    backend.offline = true;
    expect(await cart.remove(watch.id), isNull);
    expect(cart.lastError, contains('Can’t reach APM'));
    expect(cart.itemCount, 3);
  });

  test('guests have no cart', () async {
    cart.syncWith(AuthStatus.signedIn);
    cart.syncWith(AuthStatus.guest);
    await Future<void>.delayed(Duration.zero);
    expect(cart.items, isEmpty);
    expect(cart.itemCount, 0);
  });
}
