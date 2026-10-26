import '../cart/cart_item.dart' show parseAmount;
import 'order_item.dart';

/// Standard delivery fee shown before checkout (product details, cart). The real fee comes
/// from the checkout preview, because the server calculates every amount.
const standardDeliveryFeeUsd = 4.0;

/// Who and where the order goes to (the `delivery` part of a checkout request).
class Delivery {
  final String recipientName;
  final String email;
  final String address;

  const Delivery({required this.recipientName, required this.email, required this.address});

  Map<String, dynamic> toJson() => {'recipientName': recipientName.trim(), 'email': email.trim(), 'address': address.trim()};

  @override
  bool operator ==(Object other) => other is Delivery && other.recipientName.trim() == recipientName.trim() && other.email.trim() == email.trim() && other.address.trim() == address.trim();

  @override
  int get hashCode => Object.hash(recipientName.trim(), email.trim(), address.trim());
}

/// What the order will cost, as calculated by the server (POST /orders/preview).
class CheckoutPreview {
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;

  const CheckoutPreview({required this.items, required this.subtotal, required this.deliveryFee, required this.total});

  factory CheckoutPreview.fromJson(Map<String, dynamic> json) => CheckoutPreview(
        items: [for (final i in json['items'] as List) OrderItem.fromJson(i as Map<String, dynamic>)],
        subtotal: parseAmount(json['subtotal']),
        deliveryFee: parseAmount(json['deliveryFee']),
        total: parseAmount(json['total']),
      );
}
