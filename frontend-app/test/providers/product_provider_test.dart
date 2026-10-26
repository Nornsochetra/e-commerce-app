import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/models/product/product_filter.dart';
import 'package:frontend_app/providers/product/product_provider.dart';

void main() {
  late ProductProvider catalog;
  List<String> names({String? categoryId, ProductFilter filter = const ProductFilter()}) =>
      catalog.search(categoryId: categoryId, filter: filter).map((p) => p.name).toList();

  setUp(() async {
    catalog = ProductProvider();
    await catalog.load();
  });

  test('search is a case-insensitive name match and can be combined with a category', () {
    expect(names(filter: const ProductFilter(query: '  WATCH ')), ['Minimal Watch']);
    expect(names(filter: const ProductFilter(query: 'accessories')), isEmpty); // category names don't match
    final electronics = catalog.categoryBySlug('electronics')!;
    expect(names(categoryId: electronics.id), unorderedEquals(['Studio Headphones', 'Everyday Camera']));
    expect(names(categoryId: electronics.id, filter: const ProductFilter(query: 'camera')), ['Everyday Camera']);
  });

  test('in stock only hides sold-out products', () {
    expect(names(), contains('Studio Headphones'));
    expect(names(filter: const ProductFilter(inStockOnly: true)), isNot(contains('Studio Headphones')));
  });

  test('sorts: featured first, price both ways, rating, name', () {
    final featured = catalog.search(filter: const ProductFilter());
    expect(featured.take(4).every((p) => p.featured), isTrue);
    expect(featured.skip(4).any((p) => p.featured), isFalse);

    expect(names(filter: const ProductFilter(sort: ProductSort.priceLow)).first, 'Classic Sunglasses'); // $42
    expect(names(filter: const ProductFilter(sort: ProductSort.priceHigh)).first, 'Everyday Camera'); // $245
    expect(names(filter: const ProductFilter(sort: ProductSort.rating)).first, 'Studio Headphones'); // 4.9
    expect(names(filter: const ProductFilter(sort: ProductSort.name)).first, 'Canvas Backpack');
  });

  test('the saved filter is used by default and reset clears it', () {
    catalog.updateFilter(const ProductFilter(query: 'cloud', sort: ProductSort.priceHigh));
    expect(catalog.filter.hasOptions, isTrue);
    expect(names(filter: catalog.filter), ['Cloud Sneakers']);
    expect(catalog.search().map((p) => p.name), ['Cloud Sneakers']);
    catalog.resetFilter();
    expect(catalog.filter.hasOptions, isFalse);
    expect(catalog.search(), hasLength(6));
  });

  test('related products come from the same category, else featured ones', () {
    final watch = catalog.products.firstWhere((p) => p.name == 'Minimal Watch');
    expect(catalog.related(watch).map((p) => p.name), ['Classic Sunglasses']);
    final backpack = catalog.products.firstWhere((p) => p.name == 'Canvas Backpack'); // only bag
    final related = catalog.related(backpack);
    expect(related, hasLength(2));
    expect(related.every((p) => p.featured && p.id != backpack.id), isTrue);
  });
}
