import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/models/order/checkout.dart';
import 'package:frontend_app/models/order/order.dart';
import 'package:frontend_app/providers/cart/cart_provider.dart';
import 'package:frontend_app/providers/notification/notification_provider.dart';
import 'package:frontend_app/providers/order/order_provider.dart';
import 'package:frontend_app/services/api/api_client.dart';

import '../fake_api.dart';

const alex = Delivery(recipientName: 'Alex Morgan', email: 'alex@example.com', address: '12 Riverside Street, Phnom Penh');

void main() {
  late FakeBackend backend;
  late OrderProvider orders;

  setUp(() async {
    backend = FakeBackend();
    ApiClient.instance = backend.client;
    await backend.signIn();
    orders = OrderProvider();
    await orders.load();
  });

  test('order history comes from the server, newest first', () {
    expect(orders.orders.map((o) => o.reference), ['MC-19842', 'MC-20481']);
    expect(orders.totalOrders, 2);
    expect(orders.activeOrder?.reference, 'MC-19842'); // shipped, not delivered yet
    expect(orders.orders.last.itemCount, 3);
  });

  test('the checkout preview is calculated by the server', () async {
    final (preview, problem) = await orders.preview(alex);
    expect(problem, isNull);
    expect(preview!.subtotal, 205); // 1 watch + 2 backpacks
    expect(preview.deliveryFee, 4);
    expect(preview.total, 209);
    expect(preview.items.first.imageUrl, isNotEmpty);
  });

  test('placing an order: pending order, cart emptied by the server, "Order placed" notification', () async {
    final (order, problem) = await orders.placeOrder(alex, idempotencyKey: 'k1');
    expect(problem, isNull);
    expect(order!.status, OrderStatus.pending);
    expect(order.itemCount, 3);
    expect(order.total, 209);
    expect(order.recipientName, 'Alex Morgan');
    expect(orders.orders.first.id, order.id);
    expect(orders.orderById(order.id), isNotNull);
    expect(backend.adapter.requests.last.headers['Idempotency-Key'], 'k1');

    final cart = CartProvider();
    await cart.load();
    expect(cart.items, isEmpty);
    final inbox = NotificationProvider();
    await inbox.load();
    expect(inbox.items.first.title, 'Order placed');
    expect(inbox.items.first.message, contains(order.reference));
  });

  test('retrying with the same key returns the first order; changed details with that key are a CONFLICT', () async {
    final (first, _) = await orders.placeOrder(alex, idempotencyKey: 'same');
    final (retry, _) = await orders.placeOrder(alex, idempotencyKey: 'same');
    expect(retry!.id, first!.id);
    expect(orders.totalOrders, 3); // one new order, not two

    const elsewhere = Delivery(recipientName: 'Alex Morgan', email: 'alex@example.com', address: '99 Other Road, Siem Reap');
    final (none, problem) = await orders.placeOrder(elsewhere, idempotencyKey: 'same');
    expect(none, isNull);
    expect(problem?.code, 'CONFLICT');
  });

  test('an empty cart can’t be checked out', () async {
    final cart = CartProvider();
    await cart.load();
    await cart.clear();
    final (preview, problem) = await orders.preview(alex);
    expect(preview, isNull);
    expect(problem?.code, 'CART_EMPTY');
  });

  test('order details are read per order; an unknown order is reported as not found', () async {
    final shipped = orders.orders.first;
    await orders.loadOrder(shipped.id);
    expect(orders.orderById(shipped.id)!.items.single.name, 'Cloud Sneakers');
    await orders.loadOrder('no-such-order');
    expect(orders.isMissing('no-such-order'), isTrue);
  });
}
