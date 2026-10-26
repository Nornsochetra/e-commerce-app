import 'package:flutter/foundation.dart' show ChangeNotifier; // Flutter also has a class named Category

import '../../models/product/category.dart';
import '../../models/product/product.dart';
import '../../models/product/product_filter.dart';
import '../../services/product/product_service.dart';

/// The catalog: categories and products, plus the Categories screen's search, sort and filters
/// (kept here so they stay the same when the user switches tabs and comes back).
class ProductProvider extends ChangeNotifier {
  final _service = ProductService();

  List<Category> categories = [];
  List<Product> products = [];
  bool isLoading = false;
  String? error;
  ProductFilter filter = const ProductFilter();

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

  Category? categoryBySlug(String? slug) {
    for (final c in categories) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  /// Featured, in-stock products for Home "Trending now".
  List<Product> get trending => products.where((p) => p.featured && p.inStock).take(4).toList();

  /// Products marked NEW for Home "New arrivals".
  List<Product> get newArrivals => products.where((p) => p.badges.contains('NEW')).toList();

  /// Product details "You may also like": two others from the same category, or featured ones.
  List<Product> related(Product product) {
    final sameCategory = products.where((p) => p.categoryId == product.categoryId && p.id != product.id).toList();
    final list = sameCategory.isNotEmpty ? sameCategory : products.where((p) => p.featured && p.id != product.id).toList();
    return list.take(2).toList();
  }

  void updateFilter(ProductFilter value) {
    filter = value;
    notifyListeners();
  }

  /// Clears search, sort and availability.
  void resetFilter() => updateFilter(const ProductFilter());

  /// Products in [categoryId] (all when null) that match [filter].
  /// Search is a case-insensitive name contains match, as on the backend.
  List<Product> search({String? categoryId, ProductFilter? filter}) {
    final f = filter ?? this.filter;
    final q = f.query.trim().toLowerCase();
    final list = products
        .where((p) => (categoryId == null || p.categoryId == categoryId) && (q.isEmpty || p.name.toLowerCase().contains(q)) && (!f.inStockOnly || p.inStock))
        .toList();
    switch (f.sort) {
      case ProductSort.featured: // featured first, otherwise catalog order (List.sort isn't stable)
        return [...list.where((p) => p.featured), ...list.where((p) => !p.featured)];
      case ProductSort.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
      case ProductSort.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
      case ProductSort.rating:
        list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      case ProductSort.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }
}
