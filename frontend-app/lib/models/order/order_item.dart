import '../cart/cart_item.dart' show parseAmount;

/// A product line inside an order or a checkout preview (a snapshot taken at checkout).
/// Order details from the API carry no image, so [imageUrl] can be empty; screens then use the
/// catalog photo of [productId].
class OrderItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal; // calculated by the server

  const OrderItem({required this.productId, required this.name, this.imageUrl = '', required this.unitPrice, required this.quantity, required this.lineTotal});

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String? ?? '',
        unitPrice: parseAmount(json['unitPrice']),
        quantity: json['quantity'] as int,
        lineTotal: parseAmount(json['lineTotal']),
      );
}
