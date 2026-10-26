import '../../models/common/page_result.dart';
import '../../models/order/checkout.dart';
import '../../models/order/order.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';

/// Checkout and orders through the API (ORD-*). The server calculates every amount.
/// Failures throw ApiException, e.g. CART_EMPTY, INSUFFICIENT_STOCK, CHECKOUT_INVALID, CONFLICT, ORDER_NOT_FOUND.
class OrderService {
  final ApiClient _api;
  OrderService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  /// Standard delivery, paid in cash when it arrives: the only options in v1.
  Map<String, dynamic> _checkout(Delivery delivery) => {'delivery': delivery.toJson(), 'deliveryMethod': 'standard', 'paymentMethod': 'cash_on_delivery'};

  /// Checks the current cart and calculates the totals without placing the order.
  Future<CheckoutPreview> preview(Delivery delivery) async =>
      CheckoutPreview.fromJson(await _api.post('/orders/preview', body: _checkout(delivery)) as Map<String, dynamic>);

  /// Places an order from the current cart (the server then removes those items from the cart).
  /// Sending the same [idempotencyKey] again returns the first order instead of a duplicate.
  Future<Order> place(Delivery delivery, {required String idempotencyKey}) async =>
      Order.fromJson(await _api.post('/orders', body: _checkout(delivery), headers: {'Idempotency-Key': idempotencyKey}) as Map<String, dynamic>);

  /// Order history, newest first.
  Future<PageResult<OrderSummary>> getOrders({int page = 0, int size = ApiConfig.pageSize}) async =>
      PageResult.fromJson(await _api.get('/orders', query: {'page': page, 'size': size}) as Map<String, dynamic>, OrderSummary.fromJson);

  Future<Order> getOrder(String id) async => Order.fromJson(await _api.get('/orders/$id') as Map<String, dynamic>);
}
