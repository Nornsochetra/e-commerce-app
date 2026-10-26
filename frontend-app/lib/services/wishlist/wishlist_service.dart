import '../../models/common/page_result.dart';
import '../../models/product/product.dart';
import '../api/api_client.dart';

/// The wishlist through the API (WSH-*): saved products, newest first. Saving twice is harmless.
/// Failures throw ApiException.
class WishlistService {
  static const pageSize = 100; // the API maximum

  final ApiClient _api;
  WishlistService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  Future<PageResult<Product>> getPage(int page) async =>
      PageResult.fromJson(await _api.get('/wishlist/items', query: {'page': page, 'size': pageSize}) as Map<String, dynamic>, Product.fromJson);

  /// Saves a product and returns it (with its current price and stock).
  Future<Product> save(String productId) async => Product.fromJson(await _api.post('/wishlist/items', body: {'productId': productId}) as Map<String, dynamic>);

  Future<void> remove(String productId) => _api.delete('/wishlist/items/$productId');
}
