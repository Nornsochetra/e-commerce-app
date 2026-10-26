import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/mock_data.dart';
import '../../models/cart/cart_item.dart';
import '../../models/notification/app_notification.dart';
import '../../models/order/order.dart';
import '../../models/order/order_item.dart';
import '../notification/notification_service.dart';

/// Loads orders and places new ones. Later: GET /orders, GET /orders/{id}, POST /orders.
class OrderService {
  static const _key = 'orders';
  static const _keysKey = 'order_idempotency_keys'; // Idempotency-Key → order id
  final _notificationService = NotificationService();

  Future<List<Order>> getOrders() async {
    await Future.delayed(mockDelay);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return mockOrders();
    return (jsonDecode(raw) as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Creates an order from the cart. Like the backend, the totals are calculated here, not by the screen,
  /// and placing an order also creates an "Order confirmed" notification.
  /// Sending the same [idempotencyKey] again returns the first order instead of creating a duplicate
  /// (the backend's Idempotency-Key header).
  Future<Order> placeOrder({
    required String idempotencyKey,
    required List<CartItem> items,
    required String recipientName,
    required String email,
    required String address,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final prefs = await SharedPreferences.getInstance();
    final keys = Map<String, dynamic>.from(jsonDecode(prefs.getString(_keysKey) ?? '{}') as Map);
    final orders = await getOrders();
    final replayId = keys[idempotencyKey];
    if (replayId != null) return orders.firstWhere((o) => o.id == replayId);

    final now = DateTime.now();
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    final order = Order(
      id: 'o-${now.microsecondsSinceEpoch}',
      reference: 'MC-${21000 + Random().nextInt(8000)}',
      status: OrderStatus.confirmed,
      items: items.map((i) => OrderItem(productId: i.productId, name: i.name, imageUrl: i.imageUrl, unitPrice: i.unitPrice, quantity: i.quantity)).toList(),
      recipientName: recipientName.trim(),
      email: email.trim(),
      address: address.trim(),
      subtotal: subtotal,
      deliveryFee: deliveryFeeUsd,
      total: subtotal + deliveryFeeUsd,
      createdAt: now,
      updatedAt: now,
    );
    orders.insert(0, order);
    await prefs.setString(_key, jsonEncode(orders.map((e) => e.toJson()).toList()));
    await prefs.setString(_keysKey, jsonEncode({...keys, idempotencyKey: order.id}));
    await _notificationService.addNotification(
      type: NotificationType.order,
      title: 'Order confirmed',
      message: 'Order #${order.reference} has been confirmed. We’ll let you know when it ships.',
    );
    return order;
  }
}
