/// One line in the shopping cart (`CartItem` in docs/api-specification.md §4.6).
/// [id] is the cart line's own id (used to change or remove it); [productId] is the product.
class CartItem {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final String categoryName; // the cart API doesn't send it, so it is empty for API carts
  final double unitPrice;
  final int quantity;
  final int availableQuantity; // stock limit for the quantity stepper
  final double lineTotal; // calculated by the server

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    this.categoryName = '',
    required this.unitPrice,
    required this.quantity,
    required this.availableQuantity,
    required this.lineTotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    return CartItem(
      id: json['id'] as String,
      productId: product['id'] as String,
      name: product['name'] as String,
      imageUrl: product['imageUrl'] as String? ?? '',
      unitPrice: parseAmount(json['unitPrice']),
      quantity: json['quantity'] as int,
      availableQuantity: product['availableQuantity'] as int,
      lineTotal: parseAmount(json['lineTotal']),
    );
  }
}

/// `{"amount": "89.00", "currency": "USD"}` → 89.0 (for display; the server does the maths).
double parseAmount(Object? money) => double.parse((money as Map<String, dynamic>)['amount'] as String);
