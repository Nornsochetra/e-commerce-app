/// One line in the shopping cart.
class CartItem {
  final String productId;
  final String name;
  final String imageUrl;
  final String categoryName;
  final double unitPrice;
  final int quantity;
  final int availableQuantity; // stock limit for the quantity stepper

  const CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.categoryName,
    required this.unitPrice,
    required this.quantity,
    required this.availableQuantity,
  });

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        name: name,
        imageUrl: imageUrl,
        categoryName: categoryName,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        availableQuantity: availableQuantity,
      );

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String,
        categoryName: json['categoryName'] as String,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        quantity: json['quantity'] as int,
        availableQuantity: json['availableQuantity'] as int,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'imageUrl': imageUrl,
        'categoryName': categoryName,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'availableQuantity': availableQuantity,
      };
}
