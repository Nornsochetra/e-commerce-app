import 'cart_item.dart';

/// The signed-in customer's cart as the server calculates it (GET /cart and every cart change).
/// Delivery isn't included; it is added at checkout.
class Cart {
  final List<CartItem> items;
  final double subtotal;
  final int itemCount; // sum of quantities (the tab-bar badge)

  const Cart({required this.items, required this.subtotal, required this.itemCount});

  static const empty = Cart(items: [], subtotal: 0, itemCount: 0);

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        items: [for (final i in json['items'] as List) CartItem.fromJson(i as Map<String, dynamic>)],
        subtotal: parseAmount(json['subtotal']),
        itemCount: (json['itemCount'] as num).toInt(),
      );
}
