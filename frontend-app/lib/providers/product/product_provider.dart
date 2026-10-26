import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier; // Flutter also has a class named Category

import '../../models/product/category.dart';
import '../../models/product/product.dart';
import '../../models/product/product_filter.dart';
import '../../services/api/api_exception.dart';
import '../../services/product/product_service.dart';

/// The catalog from the API.
///  - [load]: categories plus the first products (featured first) for Home, related products and
///    lookups by id. Until cart, wishlist and orders come from the API (slices D–E) they only store
///    product ids, so [products] also serves those lookups.
///  - Categories screen: [showCategory] / [updateFilter] run a server-side search into [results],
///    one page at a time ([loadMoreResults]). Search, sort and filters are kept across tab switches.
///  - Product details: [loadProduct] reads one product with its description.
class ProductProvider extends ChangeNotifier {
  final ProductService _service;
  final int pageSize;

  ProductProvider({ProductService? service, this.pageSize = 20}) : _service = service ?? ProductService();

  List<Category> categories = [];
  List<Product> products = [];
  bool isLoading = false;
  String? error;

  final _known = <String, Product>{}; // every product seen so far, by id

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      categories = await _service.getCategories();
      final page = await _service.getProducts(size: ProductService.maxPageSize);
      products = page.items;
      _remember(products);
    } on ApiException catch (e) {
      error = e.userMessage;
    }
    isLoading = false;
    notifyListeners();
    if (_searchStarted) refreshResults(); // a category from the route can be resolved now
  }

  Product? productById(String id) => _details[id] ?? _known[id];

  Category? categoryBySlug(String? slug) {
    for (final c in categories) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  /// Featured, in-stock products for Home "Trending now" (the server lists featured ones first).
  List<Product> get trending => products.where((p) => p.featured && p.inStock).take(4).toList();

  /// Products marked NEW for Home "New arrivals".
  List<Product> get newArrivals => products.where((p) => p.badges.contains('NEW')).toList();

  /// Product details "You may also like": two others from the same category, or featured ones.
  List<Product> related(Product product) {
    final sameCategory = products.where((p) => p.categoryId == product.categoryId && p.id != product.id).toList();
    final list = sameCategory.isNotEmpty ? sameCategory : products.where((p) => p.featured && p.id != product.id).toList();
    return list.take(2).toList();
  }

  // ---------- Product details ----------

  final _details = <String, Product>{};
  final _detailLoading = <String>{};
  final _detailErrors = <String, ApiException>{};

  bool isLoadingProduct(String id) => _detailLoading.contains(id);

  /// True when the server says the product doesn't exist (or is no longer sold).
  bool isMissing(String id) => _detailErrors[id]?.code == 'PRODUCT_NOT_FOUND';

  /// A user-facing message when the product couldn't be loaded for another reason (e.g. offline).
  String? productError(String id) => isMissing(id) ? null : _detailErrors[id]?.userMessage;

  /// Loads one product with its description and current stock.
  Future<void> loadProduct(String id) async {
    if (_detailLoading.contains(id)) return;
    _detailLoading.add(id);
    _detailErrors.remove(id);
    notifyListeners();
    try {
      final product = await _service.getProduct(id);
      _details[id] = product;
      _known[id] = product;
    } on ApiException catch (e) {
      _detailErrors[id] = e;
    }
    _detailLoading.remove(id);
    notifyListeners();
  }

  // ---------- Search (Categories screen) ----------

  ProductFilter filter = const ProductFilter();
  List<Product> results = [];
  int resultsTotal = 0;
  bool resultsLoading = true; // until the Categories screen starts the first search
  bool resultsLoadingMore = false;
  bool resultsHasNext = false;
  String? resultsError;

  String? _categorySlug;
  bool _searchStarted = false;
  int _resultsPage = 0;
  int _searchToken = 0; // only the newest search may show its results
  Timer? _debounce;

  /// Shows a category (null = all); called by the Categories screen when its route changes.
  void showCategory(String? slug) {
    if (_searchStarted && slug == _categorySlug) return;
    _categorySlug = slug;
    _searchStarted = true;
    refreshResults();
  }

  /// Changes search, sort or filters. Typing waits 300 ms so not every key press is a request.
  void updateFilter(ProductFilter value) {
    final typingOnly = value.sort == filter.sort && value.inStockOnly == filter.inStockOnly && value.query != filter.query;
    filter = value;
    notifyListeners();
    if (!_searchStarted) return;
    _debounce?.cancel();
    if (typingOnly) {
      _debounce = Timer(const Duration(milliseconds: 300), refreshResults);
    } else {
      refreshResults();
    }
  }

  /// Clears search, sort and availability.
  void resetFilter() => updateFilter(const ProductFilter());

  /// Loads the first page of results for the current category and filter.
  Future<void> refreshResults() async {
    _debounce?.cancel();
    final token = ++_searchToken;
    if (_categorySlug != null && categories.isEmpty) {
      // The category from the route can't be resolved before the categories are loaded.
      resultsLoading = isLoading;
      resultsError = isLoading ? null : (error ?? 'Could not load products');
      notifyListeners();
      return; // load() runs the search again when it finishes
    }
    resultsLoading = true;
    resultsLoadingMore = false; // a "load more" for the previous search no longer counts
    resultsError = null;
    notifyListeners();
    try {
      final page = await _service.getProducts(
        size: pageSize,
        sort: filter.sort,
        query: filter.query,
        categoryId: categoryBySlug(_categorySlug)?.id,
        inStockOnly: filter.inStockOnly,
      );
      if (token != _searchToken) return;
      results = page.items;
      resultsTotal = page.totalElements;
      resultsHasNext = page.hasNext;
      _resultsPage = page.page;
      _remember(page.items);
    } on ApiException catch (e) {
      if (token != _searchToken) return;
      results = [];
      resultsTotal = 0;
      resultsHasNext = false;
      resultsError = e.userMessage;
    }
    resultsLoading = false;
    notifyListeners();
  }

  /// Appends the next page (called when the list is scrolled near its end).
  Future<void> loadMoreResults() async {
    if (!resultsHasNext || resultsLoading || resultsLoadingMore) return;
    final token = _searchToken;
    resultsLoadingMore = true;
    notifyListeners();
    try {
      final page = await _service.getProducts(
        page: _resultsPage + 1,
        size: pageSize,
        sort: filter.sort,
        query: filter.query,
        categoryId: categoryBySlug(_categorySlug)?.id,
        inStockOnly: filter.inStockOnly,
      );
      if (token != _searchToken) return;
      results = [...results, ...page.items];
      resultsTotal = page.totalElements;
      resultsHasNext = page.hasNext;
      _resultsPage = page.page;
      _remember(page.items);
    } on ApiException {
      // Keep what is shown; scrolling again retries.
    } finally {
      if (token == _searchToken) {
        resultsLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void _remember(List<Product> items) {
    for (final p in items) {
      _known[p.id] = _details[p.id] ?? p;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
