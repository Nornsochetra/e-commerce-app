import 'package:flutter/foundation.dart';

import '../../data/mock_data.dart' show deliveryFeeUsd;
import '../../models/cart/cart.dart';
import '../../models/cart/cart_item.dart';
import '../../models/product/product.dart';
import '../../services/api/api_exception.dart';
import '../../services/cart/cart_service.dart';
import '../auth/follows_sign_in.dart';

/// What happened when adding to the cart (used to pick the toast message).
enum AddToCartResult { added, updated, maxReached, outOfStock, failed }

/// The signed-in customer's cart, kept on the server. Every change shows the cart the server sends
/// back, so totals and stock rules are always the server's. Follows sign-in (guests have no cart).
class CartProvider extends ChangeNotifier with FollowsSignIn {
  final _service = CartService();

  Cart _cart = Cart.empty;
  bool isLoading = false;
  String? error; // couldn't load the cart
  String? lastError; // user-facing reason the last change failed
  final _updating = <String>{}; // product ids with a change in flight

  List<CartItem> get items => _cart.items;
  int get itemCount => _cart.itemCount;
  double get subtotal => _cart.subtotal;

  /// Estimated standard delivery; the real fee is calculated at checkout.
  double get deliveryFee => items.isEmpty ? 0 : deliveryFeeUsd;
  double get total => subtotal + deliveryFee;

  int quantityOf(String productId) => _find(productId)?.quantity ?? 0;

  /// True while a change to this product's cart line is being saved (its stepper is disabled).
  bool isUpdating(String productId) => _updating.contains(productId);

  @override
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      _cart = await _service.getCart();
    } on ApiException catch (e) {
      error = e.userMessage;
    }
    isLoading = false;
    notifyListeners();
  }

  /// Guests have no cart: hides it (nothing on the server changes).
  @override
  void unload() {
    _cart = Cart.empty;
    notifyListeners();
  }

  /// Adds [quantity] of [product]. The server refuses more than the available stock.
  Future<AddToCartResult> add(Product product, {int quantity = 1}) async {
    final already = quantityOf(product.id) > 0;
    final result = await _change(product.id, () => _service.addItem(product.id, quantity));
    return switch (result) {
      null => already ? AddToCartResult.updated : AddToCartResult.added,
      'PRODUCT_OUT_OF_STOCK' => AddToCartResult.outOfStock,
      'INSUFFICIENT_STOCK' => AddToCartResult.maxReached,
      _ => AddToCartResult.failed,
    };
  }

  /// Sets a line's quantity. Returns a user-facing error, or null when it worked.
  Future<String?> setQuantity(String productId, int quantity) async {
    final item = _find(productId);
    if (item == null || quantity == item.quantity) return null;
    final code = await _change(productId, () => _service.updateItem(item.id, quantity));
    return code == null ? null : lastError;
  }

  /// Removes a product's line and returns it, so the screen can offer "Undo" ([restore]).
  /// Returns null when it couldn't be removed ([lastError] says why).
  Future<CartItem?> remove(String productId) async {
    final item = _find(productId);
    if (item == null) return null;
    final code = await _change(productId, () => _service.removeItem(item.id));
    return code == null ? item : null;
  }

  /// Puts a removed line back (Undo). Returns a user-facing error, or null when it worked.
  Future<String?> restore(CartItem item) async {
    final code = await _change(item.productId, () => _service.addItem(item.productId, item.quantity));
    return code == null ? null : lastError;
  }

  /// Empties the cart (after placing an order).
  Future<void> clear() async {
    for (final item in [...items]) {
      await _change(item.productId, () => _service.removeItem(item.id));
    }
  }

  /// Runs one cart change and shows the cart the server returns.
  /// Returns null when it worked, otherwise the error code (and sets [lastError]).
  Future<String?> _change(String productId, Future<Cart> Function() request) async {
    _updating.add(productId);
    lastError = null;
    notifyListeners();
    try {
      _cart = await request();
      return null;
    } on ApiException catch (e) {
      lastError = e.userMessage;
      return e.code;
    } finally {
      _updating.remove(productId);
      notifyListeners();
    }
  }

  CartItem? _find(String productId) {
    for (final i in items) {
      if (i.productId == productId) return i;
    }
    return null;
  }
}
