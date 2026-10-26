import 'package:flutter/foundation.dart';

import '../auth/follows_sign_in.dart';
import '../../data/mock_data.dart';
import '../../models/cart/cart_item.dart';
import '../../models/product/product.dart';
import '../../services/cart/cart_service.dart';

/// What happened when adding to the cart (used to pick the toast message).
enum AddToCartResult { added, updated, maxReached, outOfStock }

/// The shopping cart: items, totals and the tab-bar badge count.
class CartProvider extends ChangeNotifier with FollowsSignIn {
  final _service = CartService();

  List<CartItem> items = [];
  bool isLoading = false;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);
  double get deliveryFee => items.isEmpty ? 0 : deliveryFeeUsd;
  double get total => subtotal + deliveryFee;

  int quantityOf(String productId) {
    for (final i in items) {
      if (i.productId == productId) return i.quantity;
    }
    return 0;
  }

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    items = await _service.getCart();
    isLoading = false;
    notifyListeners();
  }

  /// Guests have no cart: hides the items (the saved cart stays on the device).
  @override
  void unload() {
    items = [];
    notifyListeners();
  }

  /// Adds [quantity] of [product], never going above the available stock.
  Future<AddToCartResult> add(Product product, {int quantity = 1}) async {
    if (!product.inStock) return AddToCartResult.outOfStock;
    final index = items.indexWhere((i) => i.productId == product.id);
    if (index == -1) {
      items = [
        ...items,
        CartItem(
          productId: product.id,
          name: product.name,
          imageUrl: product.imageUrl,
          categoryName: product.categoryName,
          unitPrice: product.price,
          quantity: quantity.clamp(1, product.availableQuantity),
          availableQuantity: product.availableQuantity,
        ),
      ];
      await _save();
      return AddToCartResult.added;
    }
    final current = items[index];
    if (current.quantity >= product.availableQuantity) return AddToCartResult.maxReached;
    items = [...items]..[index] = current.copyWith(quantity: (current.quantity + quantity).clamp(1, product.availableQuantity));
    await _save();
    return AddToCartResult.updated;
  }

  Future<void> setQuantity(String productId, int quantity) async {
    items = items.map((i) => i.productId == productId ? i.copyWith(quantity: quantity.clamp(1, i.availableQuantity)) : i).toList();
    await _save();
  }

  /// Removes an item and returns it with its position, so the screen can offer "Undo".
  Future<(CartItem, int)?> remove(String productId) async {
    final index = items.indexWhere((i) => i.productId == productId);
    if (index == -1) return null;
    final removed = items[index];
    items = [...items]..removeAt(index);
    await _save();
    return (removed, index);
  }

  /// Puts a removed item back (Undo).
  Future<void> restore(CartItem item, int index) async {
    items = [...items]..insert(index.clamp(0, items.length), item);
    await _save();
  }

  Future<void> clear() async {
    items = [];
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    await _service.saveCart(items);
  }
}
