import 'package:flutter/foundation.dart';

import '../../models/cart/cart_item.dart';
import '../../models/order/order.dart';
import '../../services/order/order_service.dart';

/// Order history and placing new orders.
class OrderProvider extends ChangeNotifier {
  final _service = OrderService();

  List<Order> orders = [];
  bool isLoading = false;
  bool isPlacing = false;
  String? error;

  /// The first order that isn't delivered yet (Home "Order update" banner).
  Order? get activeOrder {
    for (final o in orders) {
      if (o.isActive) return o;
    }
    return null;
  }

  Order? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      orders = await _service.getOrders();
    } catch (_) {
      error = 'Could not load your orders';
    }
    isLoading = false;
    notifyListeners();
  }

  /// Places an order from the cart items. Returns the new order, or null if it failed or is already running.
  /// Use the same [idempotencyKey] when retrying, so a retry can never create a second order.
  Future<Order?> placeOrder({
    required String idempotencyKey,
    required List<CartItem> items,
    required String recipientName,
    required String email,
    required String address,
  }) async {
    if (isPlacing) return null; // guard against double taps
    isPlacing = true;
    notifyListeners();
    try {
      final order = await _service.placeOrder(idempotencyKey: idempotencyKey, items: items, recipientName: recipientName, email: email, address: address);
      orders = [order, ...orders.where((o) => o.id != order.id)];
      return order;
    } catch (_) {
      return null;
    } finally {
      isPlacing = false;
      notifyListeners();
    }
  }
}
