import 'package:flutter/foundation.dart';

import '../../models/product/product.dart';
import '../../services/api/api_exception.dart';
import '../../services/wishlist/wishlist_service.dart';
import '../auth/follows_sign_in.dart';

/// The signed-in customer's saved products, kept on the server, newest first.
/// Hearts change straight away and go back (with a message) if the server refuses.
/// Follows sign-in (guests have no wishlist).
class WishlistProvider extends ChangeNotifier with FollowsSignIn {
  final _service = WishlistService();

  List<Product> items = [];
  bool isLoading = false;
  String? error; // couldn't load the wishlist

  int get count => items.length;
  bool contains(String productId) => items.any((p) => p.id == productId);

  /// Loads every saved product (page by page), so hearts are right anywhere in the app.
  @override
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final all = <Product>[];
      var page = 0;
      while (true) {
        final result = await _service.getPage(page);
        all.addAll(result.items);
        if (!result.hasNext) break;
        page = result.nextPage;
      }
      items = all;
    } on ApiException catch (e) {
      error = e.userMessage;
    }
    isLoading = false;
    notifyListeners();
  }

  /// Guests have no wishlist: hides it (nothing on the server changes).
  @override
  void unload() {
    items = [];
    notifyListeners();
  }

  /// Saves or un-saves [product]. Returns a user-facing error, or null when it worked.
  Future<String?> toggle(Product product) => contains(product.id) ? _removeNow(product) : save(product.id, optimistic: product);

  /// Saves a product (newest first). With [optimistic] the heart fills before the server answers.
  Future<String?> save(String productId, {Product? optimistic}) async {
    final before = items;
    if (optimistic != null && !contains(productId)) {
      items = [optimistic, ...items];
      notifyListeners();
    }
    try {
      final saved = await _service.save(productId);
      items = [saved, ...items.where((p) => p.id != productId)];
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      items = before;
      notifyListeners();
      return e.userMessage;
    }
  }

  /// Removes a product and returns it, so the screen can offer "Undo" (save it again).
  /// Returns null when it couldn't be removed.
  Future<Product?> remove(String productId) async {
    final product = items.where((p) => p.id == productId).firstOrNull;
    if (product == null) return null;
    return await _removeNow(product) == null ? product : null;
  }

  Future<String?> _removeNow(Product product) async {
    final before = items;
    items = items.where((p) => p.id != product.id).toList();
    notifyListeners();
    try {
      await _service.remove(product.id);
      return null;
    } on ApiException catch (e) {
      if (e.code == 'WISHLIST_ITEM_NOT_FOUND') return null; // already gone: nothing to undo
      items = before;
      notifyListeners();
      return e.userMessage;
    }
  }
}
