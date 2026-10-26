import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/models/product/product_filter.dart';
import 'package:frontend_app/providers/product/product_provider.dart';
import 'package:frontend_app/services/api/api_client.dart';

import '../fake_api.dart';

/// Lets the provider's requests to the fake backend (and the 300 ms typing pause) finish.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 350));

void main() {
  late FakeBackend backend;
  late ProductProvider catalog;
  List<String> names() => catalog.results.map((p) => p.name).toList();

  setUp(() async {
    backend = FakeBackend();
    ApiClient.instance = backend.client;
    catalog = ProductProvider();
    await catalog.load();
  });

  test('load reads categories and products from the API (money, rating and badges converted)', () {
    expect(catalog.categories.map((c) => c.slug), ['accessories', 'footwear', 'bags', 'electronics']);
    final watch = catalog.products.firstWhere((p) => p.name == 'Minimal Watch');
    expect(watch.price, 89.0); // "89.00"
    expect(watch.rating, 4.8); // "4.8"
    expect(watch.badges, containsAll(['NEW', 'PREMIUM_PICK'])); // "new", "premium_pick", in any order
    expect(watch.cardBadge, 'NEW'); // cards prefer NEW, whatever order the API used
    expect(watch.description, isNull); // lists leave the description out
    expect(catalog.trending.map((p) => p.name), ['Minimal Watch', 'Cloud Sneakers', 'Canvas Backpack', 'Everyday Camera']);
    expect(catalog.newArrivals.map((p) => p.name), ['Minimal Watch', 'Everyday Camera']);
    expect(backend.adapter.requests.every((r) => !r.headers.containsKey('Authorization')), isTrue); // public reads
  });

  test('search runs on the server: name match, category, in stock and every sort', () async {
    catalog.showCategory(null);
    await settle();
    expect(catalog.resultsTotal, 6);

    catalog.updateFilter(const ProductFilter(query: 'WATCH'));
    await settle();
    expect(names(), ['Minimal Watch']);
    expect(backend.adapter.requests.last.queryParameters['query'], 'WATCH');

    catalog.updateFilter(const ProductFilter());
    catalog.showCategory('electronics');
    await settle();
    expect(names(), unorderedEquals(['Studio Headphones', 'Everyday Camera']));
    catalog.updateFilter(const ProductFilter(inStockOnly: true));
    await settle();
    expect(names(), ['Everyday Camera']);

    catalog.showCategory(null);
    for (final (sort, first) in [
      (ProductSort.priceLow, 'Classic Sunglasses'),
      (ProductSort.priceHigh, 'Everyday Camera'),
      (ProductSort.rating, 'Studio Headphones'),
      (ProductSort.name, 'Canvas Backpack'),
    ]) {
      catalog.updateFilter(ProductFilter(sort: sort));
      await settle();
      expect(names().first, first, reason: sort.name);
    }
  });

  test('typing waits for a pause before searching', () async {
    catalog.showCategory(null);
    await settle();
    final before = backend.calls('GET', '/products');
    catalog.updateFilter(const ProductFilter(query: 'c'));
    catalog.updateFilter(const ProductFilter(query: 'ca'));
    catalog.updateFilter(const ProductFilter(query: 'cam'));
    await settle();
    expect(backend.calls('GET', '/products'), before + 1); // one request for "cam", not three
    expect(names(), ['Everyday Camera']);
  });

  test('results load one page at a time', () async {
    catalog = ProductProvider(pageSize: 4);
    await catalog.load();
    catalog.showCategory(null);
    await settle();
    expect(catalog.results, hasLength(4));
    expect(catalog.resultsHasNext, isTrue);
    expect(catalog.resultsTotal, 6);

    await catalog.loadMoreResults();
    expect(catalog.results, hasLength(6));
    expect(catalog.resultsHasNext, isFalse);
    await catalog.loadMoreResults(); // nothing more to load
    expect(catalog.results, hasLength(6));
  });

  test('product details add the description; a missing product is reported as not found', () async {
    final camera = catalog.products.firstWhere((p) => p.name == 'Everyday Camera');
    await catalog.loadProduct(camera.id);
    expect(catalog.productById(camera.id)!.description, 'A compact camera for documenting the moments that matter.');

    await catalog.loadProduct('00000000-0000-4000-8000-000000000000');
    expect(catalog.isMissing('00000000-0000-4000-8000-000000000000'), isTrue);
  });

  test('related products come from the same category, else featured ones', () {
    final watch = catalog.products.firstWhere((p) => p.name == 'Minimal Watch');
    expect(catalog.related(watch).map((p) => p.name), ['Classic Sunglasses']);
    final backpack = catalog.products.firstWhere((p) => p.name == 'Canvas Backpack'); // only bag
    expect(catalog.related(backpack).every((p) => p.featured && p.id != backpack.id), isTrue);
  });
}
