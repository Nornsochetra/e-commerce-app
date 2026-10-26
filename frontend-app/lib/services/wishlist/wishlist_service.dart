import '../../models/common/page_result.dart';
import '../../models/product/product.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';

/// The wishlist through the API (WSH-*): saved products, newest first, one page at a time.
/// Saving twice is harmless. Failures throw ApiException.
class WishlistService {
  final ApiClient _api;
  WishlistService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  Future<PageResult<Product>> getPage(int page, {int size = ApiConfig.pageSize}) async =>
      PageResult.fromJson(await _api.get('/wishlist/items', query: {'page': page, 'size': size}) as Map<String, dynamic>, Product.fromJson);

  /// Saves a product and returns it, plus whether it is newly saved (201) or was already saved (200).
  Future<(Product, bool)> save(String productId) async {
    final (data, status) = await _api.postWithStatus('/wishlist/items', body: {'productId': productId});
    return (Product.fromJson(data as Map<String, dynamic>), status == 201);
  }

  Future<void> remove(String productId) => _api.delete('/wishlist/items/$productId');
}
