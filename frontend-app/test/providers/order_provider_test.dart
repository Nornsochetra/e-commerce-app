import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/data/mock_data.dart';
import 'package:frontend_app/models/order/order.dart';
import 'package:frontend_app/providers/cart/cart_provider.dart';
import 'package:frontend_app/providers/order/order_provider.dart';
import 'package:frontend_app/services/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_api.dart';

void main() {
  // Orders are still mock data (slice E); the cart they are made from comes from the fake API.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final backend = FakeBackend();
    ApiClient.instance = backend.client;
    await backend.signIn();
  });

  test('placing an order snapshots the cart and adds the delivery fee to the total', () async {
    final cart = CartProvider();
    await cart.load(); // 1 watch ($89) + 2 backpacks ($58)
    final orders = OrderProvider();
    await orders.load();

    final order = await orders.placeOrder(idempotencyKey: 'k1', items: cart.items, recipientName: ' Alex ', email: 'alex@example.com', address: '12 Riverside Street');
    expect(order, isNotNull);
    expect(order!.status, OrderStatus.confirmed);
    expect(order.itemCount, 3);
    expect(order.subtotal, 205);
    expect(order.total, 205 + deliveryFeeUsd);
    expect(order.recipientName, 'Alex');
    expect(orders.orders.first.id, order.id);
    expect(orders.activeOrder?.id, order.id);
  });

  test('retrying with the same idempotency key returns the first order instead of a duplicate', () async {
    final cart = CartProvider();
    await cart.load();
    final orders = OrderProvider();
    await orders.load();
    final before = orders.orders.length;

    final first = await orders.placeOrder(idempotencyKey: 'same', items: cart.items, recipientName: 'Alex', email: 'a@b.co', address: '12 Riverside Street');
    final retry = await orders.placeOrder(idempotencyKey: 'same', items: cart.items, recipientName: 'Alex', email: 'a@b.co', address: '12 Riverside Street');
    expect(retry!.id, first!.id);
    expect(orders.orders.length, before + 1);

    final reopened = OrderProvider();
    await reopened.load(); // saved between app starts
    expect(reopened.orders.length, before + 1);
  });
}
