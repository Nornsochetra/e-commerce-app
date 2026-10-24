/// A product line saved inside an order (a snapshot taken at checkout).
class OrderItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final int quantity;

  const OrderItem({required this.productId, required this.name, required this.imageUrl, required this.unitPrice, required this.quantity});

  double get lineTotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        quantity: json['quantity'] as int,
      );

  Map<String, dynamic> toJson() => {'productId': productId, 'name': name, 'imageUrl': imageUrl, 'unitPrice': unitPrice, 'quantity': quantity};
}
