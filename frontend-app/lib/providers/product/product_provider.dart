import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier; // Flutter also has a class named Category

import '../../models/product/category.dart';
import '../../models/product/product.dart';
import '../../models/product/product_filter.dart';
import '../../services/api/api_config.dart';
import '../../services/api/api_exception.dart';
import '../../services/product/product_service.dart';
import '../auth/auth_provider.dart';

/// The catalog from the API. Everything is loaded when a screen needs it, in small pages:
///  - Home: [ensureHome] reads the categories and the first products of each Home section.
///  - Categories: [showCategory] / [updateFilter] run a server-side search into [results], one page
///    at a time ([loadMoreResults]). Search, sort and filters are kept across tab switches.
///  - Product details: [loadProduct] reads one product; [loadRelated] its "You may also like" list.
/// When someone signs in or out nothing is requested: the data is only marked out of date (and the
/// previous person's hearts are cleared), and each screen reads it again when it is next shown
/// ([syncAuth], [ensureHome], [ensureResults], [ensureProduct]).
class ProductProvider extends ChangeNotifier {
  final ProductService _service;
  final int pageSize;

  ProductProvider({ProductService? service, this.pageSize = ApiConfig.pageSize}) : _service = service ?? ProductService();

  final _known = <String, Product>{}; // every product seen so far, by id
  bool? _signedIn;

  void _remember(List<Product> items) {
    for (final p in items) {
      _known[p.id] = p;
    }
  }

  Product? productById(String id) => _details[id] ?? _known[id];

  /// A product whose name appears in [text] (used to open a "Back in stock" notification), if known.
  Product? productMentionedIn(String text) => _known.values.where((p) => text.contains(p.name)).firstOrNull;

  /// Called by main.dart whenever the sign-in state changes.
  void syncAuth(AuthStatus status) {
    if (status == AuthStatus.unknown) return;
    final signedIn = status == AuthStatus.signedIn;
    if (signedIn == _signedIn) return;
    final firstTime = _signedIn == null;
    _signedIn = signedIn;
    if (firstTime) return;
    // The `saved` flags belonged to the previous person. Request nothing now (the next screen may be
    // Sign in); mark what was loaded as out of date so Home, Categories and product details read it
    // again when they are next shown. After signing out the old hearts are simply cleared.
    _homeStale = _homeRequested;
    _resultsStale = _searchStarted;
    _details.clear();
    _related.clear();
    if (!signedIn) {
      trending = [for (final p in trending) p.withSaved(false)];
      newArrivals = [for (final p in newArrivals) p.withSaved(false)];
      results = [for (final p in results) p.withSaved(false)];
      _known.updateAll((_, p) => p.withSaved(false));
    }
    scheduleMicrotask(notifyListeners); // providers can't notify while widgets are building
  }

  // ---------- Categories and Home ----------

  List<Category> categories = [];
  List<Product> trending = []; // Home "Trending now": featured, in stock
  List<Product> newArrivals = []; // Home "New arrivals": newest first
  bool isLoading = false;
  String? error;
  bool _homeRequested = false;
  bool _homeStale = false; // signed in or out since Home was loaded
  Future<void>? _categoriesLoading;

  /// Loads Home the first time it is shown, and again if someone signed in or out since.
  Future<void> ensureHome() async {
    if (_homeRequested && !_homeStale) return;
    _homeRequested = true;
    _homeStale = false;
    await loadHome();
  }

  /// Reads the categories and the first products of each Home section (pull to refresh calls this).
  Future<void> loadHome() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // The three requests run at the same time.
      final featured = _service.getProducts(sort: ProductSort.featured, inStockOnly: true, size: ApiConfig.homeSectionSize);
      final newest = _service.getProducts(sort: ProductSort.newest, size: ApiConfig.homeSectionSize);
      final categoryList = _loadCategories(force: true);
      trending = (await featured).items.where((p) => p.featured).toList();
      newArrivals = (await newest).items;
      await categoryList;
      _remember([...trending, ...newArrivals]);
    } on ApiException catch (e) {
      error = e.userMessage;
    }
    isLoading = false;
    notifyListeners();
  }

  /// Loads the category list if no screen has yet (the Categories screen needs it for its chips).
  Future<void> ensureCategories() async {
    if (categories.isNotEmpty) return;
    try {
      await _loadCategories();
    } on ApiException {
      // The chips stay empty; the product list shows its own error.
    }
  }

  Future<void> _loadCategories({bool force = false}) {
    if (!force && _categoriesLoading != null) return _categoriesLoading!;
    return _categoriesLoading = () async {
      try {
        categories = await _service.getCategories();
        notifyListeners();
      } finally {
        _categoriesLoading = null;
      }
    }();
  }

  Category? categoryBySlug(String? slug) {
    for (final c in categories) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  // ---------- Product details ----------

  final _details = <String, Product>{};
  final _detailLoading = <String>{};
  final _detailErrors = <String, ApiException>{};

  bool isLoadingProduct(String id) => _detailLoading.contains(id);

  /// Reads the product unless it is already loaded (or loading, or known to have failed).
  /// Product details call this when shown, so it re-reads after a sign-in or sign-out.
  void ensureProduct(String id) {
    if (_details.containsKey(id) || _detailLoading.contains(id) || _detailErrors.containsKey(id)) return;
    loadProduct(id);
  }

  /// True when the server says the product doesn't exist (or is no longer sold).
  bool isMissing(String id) => _detailErrors[id]?.code == 'PRODUCT_NOT_FOUND';

  /// A user-facing message when the product couldn't be loaded for another reason (e.g. offline).
  String? productError(String id) => isMissing(id) ? null : _detailErrors[id]?.userMessage;

  /// Loads one product with its description, current stock and saved state.
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

  final _related = <String, List<Product>>{};

  /// "You may also like" for a product, once [loadRelated] has read it.
  List<Product> relatedTo(String productId) => _related[productId] ?? const [];

  /// Two other products from the same category, or featured ones when the category has no others.
  Future<void> loadRelated(Product product) async {
    if (_related.containsKey(product.id)) return;
    _related[product.id] = const [];
    try {
      var list = (await _service.getProducts(categoryId: product.categoryId, size: ApiConfig.relatedSize)).items.where((p) => p.id != product.id).toList();
      if (list.isEmpty) list = (await _service.getProducts(size: ApiConfig.relatedSize)).items.where((p) => p.featured && p.id != product.id).toList();
      _related[product.id] = list.take(2).toList();
      _remember(list);
    } on ApiException {
      _related.remove(product.id); // try again next time the product is opened
    }
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
  bool _resultsStale = false; // signed in or out since the results were loaded
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

  /// Re-runs the search when the Categories screen is shown again after a sign-in or sign-out.
  void ensureResults() {
    if (_resultsStale) refreshResults();
  }

  /// Loads the first page of results for the current category and filter.
  Future<void> refreshResults() async {
    _debounce?.cancel();
    _resultsStale = false;
    final token = ++_searchToken;
    resultsLoading = true;
    resultsLoadingMore = false; // a "load more" for the previous search no longer counts
    resultsError = null;
    notifyListeners();
    try {
      if (_categorySlug != null) await ensureCategories(); // to turn the route's slug into an id
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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
