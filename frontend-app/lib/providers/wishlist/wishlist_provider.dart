import 'package:flutter/foundation.dart';

import '../../services/wishlist/wishlist_service.dart';

/// Saved products (stored as product ids; screens look the products up in ProductProvider).
class WishlistProvider extends ChangeNotifier {
  final _service = WishlistService();

  List<String> productIds = [];
  bool isLoading = false;

  int get count => productIds.length;
  bool contains(String productId) => productIds.contains(productId);

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    productIds = await _service.getWishlistIds();
    isLoading = false;
    notifyListeners();
  }

  /// Adds or removes a product; returns true when it is now saved.
  Future<bool> toggle(String productId) async {
    final saved = !contains(productId);
    productIds = saved ? [...productIds, productId] : productIds.where((id) => id != productId).toList();
    await _save();
    return saved;
  }

  /// Removes a product and returns its position, so the screen can offer "Undo".
  Future<int> remove(String productId) async {
    final index = productIds.indexOf(productId);
    if (index == -1) return -1;
    productIds = [...productIds]..removeAt(index);
    await _save();
    return index;
  }

  Future<void> restore(String productId, int index) async {
    if (contains(productId)) return;
    productIds = [...productIds]..insert(index.clamp(0, productIds.length), productId);
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    await _service.saveWishlistIds(productIds);
  }
}
