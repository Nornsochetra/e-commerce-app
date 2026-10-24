import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/data/mock_data.dart';
import 'package:frontend_app/providers/cart/cart_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts with the demo cart and computes totals', () async {
    final cart = CartProvider();
    await cart.load();
    expect(cart.itemCount, 3); // 1 watch + 2 backpacks
    expect(cart.subtotal, 89 + 2 * 58);
    expect(cart.total, cart.subtotal + deliveryFeeUsd);
  });

  test('adding never goes above stock', () async {
    final cart = CartProvider();
    await cart.load();
    final camera = mockProducts.firstWhere((p) => p.name == 'Everyday Camera'); // 3 in stock
    expect(await cart.add(camera, quantity: 2), AddToCartResult.added);
    expect(await cart.add(camera, quantity: 5), AddToCartResult.updated);
    expect(cart.quantityOf(camera.id), 3);
    expect(await cart.add(camera), AddToCartResult.maxReached);
    final headphones = mockProducts.firstWhere((p) => p.name == 'Studio Headphones'); // sold out
    expect(await cart.add(headphones), AddToCartResult.outOfStock);
  });

  test('remove and undo, and the cart is saved between app starts', () async {
    final cart = CartProvider();
    await cart.load();
    final removed = await cart.remove(mockProducts[0].id);
    expect(cart.itemCount, 2);
    await cart.restore(removed!.$1, removed.$2);
    expect(cart.itemCount, 3);
    await cart.setQuantity(mockProducts[0].id, 4);

    final reopened = CartProvider();
    await reopened.load();
    expect(reopened.quantityOf(mockProducts[0].id), 4);
  });
}
