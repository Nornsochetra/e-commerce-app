import 'package:flutter/foundation.dart';

import '../../models/order/checkout.dart';
import '../../models/order/order.dart';
import '../../services/api/api_exception.dart';
import '../../services/order/order_service.dart';
import '../auth/follows_sign_in.dart';

/// Checkout, order history (one page at a time) and order details, all from the server.
/// Follows sign-in (guests have no orders).
class OrderProvider extends ChangeNotifier with FollowsSignIn {
  final _service = OrderService();

  List<OrderSummary> orders = []; // newest first
  int totalOrders = 0;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasNext = false;
  String? error;
  bool isPlacing = false;
  int _page = 0;

  final _details = <String, Order>{};
  final _detailLoading = <String>{};
  final _detailErrors = <String, ApiException>{};

  /// The newest order that isn't delivered yet (Home "Order update" banner).
  OrderSummary? get activeOrder => orders.where((o) => o.isActive).firstOrNull;

  /// The full order, once [loadOrder] (or placing it) has read it.
  Order? orderById(String id) => _details[id];

  OrderSummary? summaryByReference(String reference) => orders.where((o) => o.reference == reference).firstOrNull;

  bool isLoadingOrder(String id) => _detailLoading.contains(id);
  bool isMissing(String id) => _detailErrors[id]?.code == 'ORDER_NOT_FOUND';
  String? orderError(String id) => isMissing(id) ? null : _detailErrors[id]?.userMessage;

  @override
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _service.getOrders();
      orders = page.items;
      totalOrders = page.totalElements;
      hasNext = page.hasNext;
      _page = page.page;
    } on ApiException catch (e) {
      error = e.userMessage;
    }
    isLoading = false;
    notifyListeners();
  }

  /// Appends the next page of order history (called while scrolling).
  Future<void> loadMore() async {
    if (!hasNext || isLoading || isLoadingMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _service.getOrders(page: _page + 1);
      orders = [...orders, ...page.items];
      totalOrders = page.totalElements;
      hasNext = page.hasNext;
      _page = page.page;
    } on ApiException {
      // Keep what is shown; scrolling again retries.
    }
    isLoadingMore = false;
    notifyListeners();
  }

  /// Guests have no orders: hides them (nothing on the server changes).
  @override
  void unload() {
    orders = [];
    totalOrders = 0;
    hasNext = false;
    _details.clear();
    _detailErrors.clear();
    notifyListeners();
  }

  /// Reads one order with its lines and delivery details.
  Future<void> loadOrder(String id) async {
    if (_detailLoading.contains(id)) return;
    _detailLoading.add(id);
    _detailErrors.remove(id);
    notifyListeners();
    try {
      _details[id] = await _service.getOrder(id);
    } on ApiException catch (e) {
      _detailErrors[id] = e;
    }
    _detailLoading.remove(id);
    notifyListeners();
  }

  /// What the current cart will cost with this delivery, calculated by the server.
  /// Returns the preview, or the reason it couldn't be made (e.g. INSUFFICIENT_STOCK).
  Future<(CheckoutPreview?, ApiException?)> preview(Delivery delivery) async {
    try {
      return (await _service.preview(delivery), null);
    } on ApiException catch (e) {
      return (null, e);
    }
  }

  /// Places an order from the cart. Use the same [idempotencyKey] when retrying the same details,
  /// so a retry can never create a second order. Returns the order, or the reason it failed.
  Future<(Order?, ApiException?)> placeOrder(Delivery delivery, {required String idempotencyKey}) async {
    if (isPlacing) return (null, null); // guard against double taps
    isPlacing = true;
    notifyListeners();
    try {
      final order = await _service.place(delivery, idempotencyKey: idempotencyKey);
      _details[order.id] = order;
      if (!orders.any((o) => o.id == order.id)) {
        orders = [order.toSummary(), ...orders];
        totalOrders++;
      }
      return (order, null);
    } on ApiException catch (e) {
      return (null, e);
    } finally {
      isPlacing = false;
      notifyListeners();
    }
  }
}
