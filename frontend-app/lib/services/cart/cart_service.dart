import '../../models/cart/cart.dart';
import '../api/api_client.dart';

/// The cart through the API (CRT-*). Every change returns the whole updated cart, so totals and
/// stock rules always come from the server. Failures throw ApiException, e.g. PRODUCT_OUT_OF_STOCK,
/// INSUFFICIENT_STOCK or CART_ITEM_NOT_FOUND.
class CartService {
  final ApiClient _api;
  CartService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  Future<Cart> getCart() async => Cart.fromJson(await _api.get('/cart') as Map<String, dynamic>);

  /// Adds [quantity] of a product; if it is already in the cart, its quantity goes up.
  Future<Cart> addItem(String productId, int quantity) async =>
      Cart.fromJson(await _api.post('/cart/items', body: {'productId': productId, 'quantity': quantity}) as Map<String, dynamic>);

  /// Sets (doesn't add to) the quantity of one cart line.
  Future<Cart> updateItem(String itemId, int quantity) async =>
      Cart.fromJson(await _api.patch('/cart/items/$itemId', body: {'quantity': quantity}) as Map<String, dynamic>);

  Future<Cart> removeItem(String itemId) async => Cart.fromJson(await _api.delete('/cart/items/$itemId') as Map<String, dynamic>);
}
