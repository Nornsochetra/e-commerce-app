/// A product category, e.g. "Accessories".
class Category {
  final String id;
  final String name;
  final String slug;

  const Category({required this.id, required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json['id'] as String, name: json['name'] as String, slug: json['slug'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}
