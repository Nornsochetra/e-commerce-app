/// A product in the catalog.
class Product {
  final String id;
  final String name;
  final String? description;
  final String categoryId;
  final String categoryName;
  final double price; // USD
  final int availableQuantity;
  final double? rating;
  final String imageUrl; // product photos come from the API, so they stay as URLs
  final List<String> badges; // e.g. NEW, BESTSELLER, PREMIUM_PICK
  final bool featured;
  final bool saved; // in the signed-in customer's wishlist (always false for guests)

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.availableQuantity,
    this.rating,
    required this.imageUrl,
    this.badges = const [],
    this.featured = false,
    this.saved = false,
  });

  bool get inStock => availableQuantity > 0;

  /// The same product with another saved state (e.g. clearing hearts after signing out).
  Product withSaved(bool value) => Product(
        id: id,
        name: name,
        description: description,
        categoryId: categoryId,
        categoryName: categoryName,
        price: price,
        availableQuantity: availableQuantity,
        rating: rating,
        imageUrl: imageUrl,
        badges: badges,
        featured: featured,
        saved: value,
      );

  /// Badges in display order. The API sends them in no particular order, and the client picks
  /// the right one per context (docs/api-specification.md §4.4): NEW first, then BESTSELLER, PREMIUM_PICK.
  List<String> get badgesInOrder {
    const order = ['NEW', 'BESTSELLER', 'PREMIUM_PICK'];
    int rank(String b) => order.contains(b) ? order.indexOf(b) : order.length;
    return [...badges]..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  /// The one badge shown on product cards, or null.
  String? get cardBadge => badges.isEmpty ? null : badgesInOrder.first;

  /// "Only 3 left" style warning threshold used on product details.
  bool get lowStock => availableQuantity > 0 && availableQuantity <= 5;

  /// Reads `ProductSummary` / `ProductDetail` from the API (docs/api-specification.md §4.4–4.5).
  /// The list leaves out `description`; product details include it (it may be null).
  /// Money arrives as a decimal string (`{"amount": "89.00", "currency": "USD"}`); the app only
  /// displays it, and the server calculates every total. Badges arrive lowercase ("premium_pick").
  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>;
    final price = json['price'] as Map<String, dynamic>;
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: category['id'] as String,
      categoryName: category['name'] as String,
      price: double.parse(price['amount'] as String),
      availableQuantity: json['availableQuantity'] as int,
      rating: json['rating'] == null ? null : double.tryParse(json['rating'].toString()),
      imageUrl: json['imageUrl'] as String? ?? '',
      badges: [for (final b in json['badges'] as List? ?? const []) (b as String).toUpperCase()],
      featured: json['featured'] as bool? ?? false,
      saved: json['saved'] as bool? ?? false,
    );
  }
}
