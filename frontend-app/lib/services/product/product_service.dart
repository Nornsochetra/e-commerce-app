import '../../data/mock_data.dart';
import '../../models/product/category.dart';
import '../../models/product/product.dart';

/// Loads the catalog. Later: GET /categories, GET /products, GET /products/{id}.
class ProductService {
  Future<List<Category>> getCategories() async {
    await Future.delayed(mockDelay);
    return mockCategories;
  }

  Future<List<Product>> getProducts() async {
    await Future.delayed(mockDelay);
    return mockProducts;
  }
}
