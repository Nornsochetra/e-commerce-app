import 'package:flutter/foundation.dart';

import '../../models/product/product.dart';
import '../../services/api/api_exception.dart';
import '../../services/wishlist/wishlist_service.dart';
import '../auth/follows_sign_in.dart';

/// The signed-in customer's saved products, kept on the server.
///  - Hearts: every product from the API says whether it is `saved`; a heart tapped in this session
///    wins over that ([isSaved]). So hearts need no wishlist download.
///  - Wishlist screen: [ensureLoaded] reads the first page (newest first), [loadMore] the next ones.
/// Hearts change straight away and go back (with a message) if the server refuses.
/// Follows sign-in (guests have no wishlist).
class WishlistProvider extends ChangeNotifier with FollowsSignIn {
  final _service = WishlistService();

  List<Product> items = []; // loaded pages, newest first
  int total = 0; // all saved products on the server
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasNext = false;
  String? error; // couldn't load the wishlist
  int _page = 0;
  final _toggled = <String, bool>{}; // product id → saved, for hearts tapped in this session

  int get count => total;

  /// Whether [product] is saved: a heart tapped in this session wins over the product's `saved` flag.
  bool isSaved(Product product) => _toggled[product.id] ?? product.saved;

  @override
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _service.getPage(0);
      items = page.items;
      total = page.totalElements;
      hasNext = page.hasNext;
      _page = page.page;
    } on ApiException catch (e) {
      error = e.userMessage;
    }
    isLoading = false;
    notifyListeners();
  }

  /// Appends the next page (called while scrolling the Wishlist screen).
  Future<void> loadMore() async {
    if (!hasNext || isLoading || isLoadingMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _service.getPage(_page + 1);
      items = [...items, ...page.items.where((p) => !items.any((i) => i.id == p.id))];
      total = page.totalElements;
      hasNext = page.hasNext;
      _page = page.page;
    } on ApiException {
      // Keep what is shown; scrolling again retries.
    }
    isLoadingMore = false;
    notifyListeners();
  }

  /// Guests have no wishlist: hides it (nothing on the server changes).
  @override
  void unload() {
    items = [];
    total = 0;
    hasNext = false;
    _toggled.clear();
    notifyListeners();
  }

  /// Saves or un-saves [product]. Returns a user-facing error, or null when it worked.
  Future<String?> toggle(Product product) async {
    if (isSaved(product)) return unsave(product.id);
    final (error, _) = await save(product.id);
    return error;
  }

  /// Saves a product (the heart fills before the server answers).
  /// Returns a user-facing error (or null) and whether it is newly saved (false if it already was).
  Future<(String?, bool)> save(String productId) async {
    final before = (items, total, _toggled[productId]);
    _toggled[productId] = true;
    notifyListeners();
    try {
      final (saved, isNew) = await _service.save(productId);
      items = [saved, ...items.where((p) => p.id != productId)];
      if (isNew) total++;
      notifyListeners();
      return (null, isNew);
    } on ApiException catch (e) {
      _restore(productId, before);
      return (e.userMessage, false);
    }
  }

  /// Removes a product (the heart empties before the server answers).
  /// Returns a user-facing error, or null when it worked.
  Future<String?> unsave(String productId) async {
    final before = (items, total, _toggled[productId]);
    _toggled[productId] = false;
    items = items.where((p) => p.id != productId).toList();
    total = total > 0 ? total - 1 : 0;
    notifyListeners();
    try {
      await _service.remove(productId);
      return null;
    } on ApiException catch (e) {
      if (e.code == 'WISHLIST_ITEM_NOT_FOUND') {
        total = before.$2; // it wasn't saved, so the count was right
        notifyListeners();
        return null;
      }
      _restore(productId, before);
      return e.userMessage;
    }
  }

  void _restore(String productId, (List<Product>, int, bool?) before) {
    items = before.$1;
    total = before.$2;
    if (before.$3 == null) {
      _toggled.remove(productId);
    } else {
      _toggled[productId] = before.$3!;
    }
    notifyListeners();
  }
}
