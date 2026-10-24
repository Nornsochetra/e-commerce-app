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
  });

  bool get inStock => availableQuantity > 0;

  /// "Only 3 left" style warning threshold used on product details.
  bool get lowStock => availableQuantity > 0 && availableQuantity <= 5;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
        price: (json['price'] as num).toDouble(),
        availableQuantity: json['availableQuantity'] as int,
        rating: (json['rating'] as num?)?.toDouble(),
        imageUrl: json['imageUrl'] as String,
        badges: List<String>.from(json['badges'] as List? ?? const []),
        featured: json['featured'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'price': price,
        'availableQuantity': availableQuantity,
        'rating': rating,
        'imageUrl': imageUrl,
        'badges': badges,
        'featured': featured,
      };
}
