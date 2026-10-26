/// How the product list is ordered (docs/features/product-catalog.md §6).
enum ProductSort {
  featured('Featured'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  rating('Top rated'),
  name('Name: A to Z');

  final String label;
  const ProductSort(this.label);
}

/// Search text, sort and filters for the Categories screen. Later these become the
/// query parameters of GET /products (q, sort, inStock); the category comes from the route.
class ProductFilter {
  final String query;
  final ProductSort sort;
  final bool inStockOnly;

  const ProductFilter({this.query = '', this.sort = ProductSort.featured, this.inStockOnly = false});

  /// True when sort or availability differ from the defaults (shows a dot on the filter button).
  bool get hasOptions => sort != ProductSort.featured || inStockOnly;

  ProductFilter copyWith({String? query, ProductSort? sort, bool? inStockOnly}) =>
      ProductFilter(query: query ?? this.query, sort: sort ?? this.sort, inStockOnly: inStockOnly ?? this.inStockOnly);
}
