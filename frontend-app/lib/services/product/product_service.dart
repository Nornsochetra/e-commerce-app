import '../../models/common/page_result.dart';
import '../../models/product/category.dart';
import '../../models/product/product.dart';
import '../../models/product/product_filter.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';

/// The catalog through the API: GET /categories (CAT-0101), GET /products (CAT-0102),
/// GET /products/{id} (CAT-0601). Catalog reads are public; the token is sent when signed in, so
/// each product says whether it is `saved` in the customer's wishlist.
/// Failures throw ApiException (PRODUCT_NOT_FOUND for a missing product).
class ProductService {
  final ApiClient _api;
  ProductService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  Future<List<Category>> getCategories() async {
    final data = await _api.get('/categories', auth: false) as List;
    return [for (final c in data) Category.fromJson(c as Map<String, dynamic>)];
  }

  /// One page of products. Search is a case-insensitive name match done by the server.
  Future<PageResult<Product>> getProducts({
    int page = 0,
    int size = ApiConfig.pageSize,
    ProductSort sort = ProductSort.featured,
    String? query,
    String? categoryId,
    bool inStockOnly = false,
  }) async {
    final data = await _api.get('/products', query: {
      'page': page,
      'size': size,
      'sort': _sortParam(sort),
      'query': (query == null || query.trim().isEmpty) ? null : query.trim(),
      'categoryId': categoryId,
      'inStock': inStockOnly ? true : null,
    });
    return PageResult.fromJson(data as Map<String, dynamic>, Product.fromJson);
  }

  /// One product with its description and current stock.
  Future<Product> getProduct(String id) async => Product.fromJson(await _api.get('/products/$id') as Map<String, dynamic>);

  /// The API's sort values (docs/api-specification.md §3.4).
  static String _sortParam(ProductSort sort) => switch (sort) {
        ProductSort.featured => 'featured,asc',
        ProductSort.priceLow => 'price,asc',
        ProductSort.priceHigh => 'price,desc',
        ProductSort.rating => 'rating,desc',
        ProductSort.name => 'name,asc',
        ProductSort.newest => 'createdAt,desc',
      };
}
