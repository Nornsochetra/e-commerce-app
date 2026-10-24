import 'package:flutter/foundation.dart' show ChangeNotifier; // Flutter also has a class named Category

import '../../models/product/category.dart';
import '../../models/product/product.dart';
import '../../services/product/product_service.dart';

/// The catalog: categories and products.
class ProductProvider extends ChangeNotifier {
  final _service = ProductService();

  List<Category> categories = [];
  List<Product> products = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      categories = await _service.getCategories();
      products = await _service.getProducts();
    } catch (_) {
      error = 'Could not load products';
    }
    isLoading = false;
    notifyListeners();
  }

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Featured, in-stock products for Home "Trending now".
  List<Product> get trending => products.where((p) => p.featured && p.inStock).take(4).toList();

  /// Products marked NEW for Home "New arrivals".
  List<Product> get newArrivals => products.where((p) => p.badges.contains('NEW')).toList();
}
