import '../cart/cart_item.dart' show parseAmount;
import 'order_item.dart';

/// Order status flow: pending → confirmed → shipped → delivered.
enum OrderStatus { pending, confirmed, shipped, delivered }

/// A placed order with its lines, delivery details and amounts (`OrderDetail`, docs/api.md, API specification §4.9).
/// Order history only lists [OrderSummary]s; the full order is read per order.
class Order {
  final String id;
  final String reference; // e.g. MC-1A2B3C4D5E6F
  final OrderStatus status;
  final List<OrderItem> items;
  final String recipientName;
  final String email;
  final String address;
  final String paymentMethod; // only "cash_on_delivery" in v1
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.reference,
    required this.status,
    required this.items,
    required this.recipientName,
    required this.email,
    required this.address,
    this.paymentMethod = 'cash_on_delivery',
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isActive => status != OrderStatus.delivered;

  factory Order.fromJson(Map<String, dynamic> json) {
    final delivery = json['delivery'] as Map<String, dynamic>;
    final createdAt = DateTime.parse(json['createdAt'] as String);
    return Order(
      id: json['id'] as String,
      reference: json['reference'] as String,
      status: OrderStatus.values.byName(json['status'] as String),
      items: [for (final i in json['items'] as List) OrderItem.fromJson(i as Map<String, dynamic>)],
      recipientName: delivery['recipientName'] as String,
      email: delivery['email'] as String,
      address: delivery['address'] as String,
      paymentMethod: json['paymentMethod'] as String? ?? 'cash_on_delivery',
      subtotal: parseAmount(json['subtotal']),
      deliveryFee: parseAmount(json['deliveryFee']),
      total: parseAmount(json['total']),
      createdAt: createdAt,
      updatedAt: json['updatedAt'] == null ? createdAt : DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// The short form used by order history (e.g. right after placing an order).
  OrderSummary toSummary() => OrderSummary(id: id, reference: reference, status: status, itemCount: itemCount, total: total, createdAt: createdAt);
}

/// One row of order history (`OrderSummary`, docs/api.md, API specification §4.10). It has no item lines.
class OrderSummary {
  final String id;
  final String reference;
  final OrderStatus status;
  final int itemCount;
  final double total;
  final DateTime createdAt;

  const OrderSummary({required this.id, required this.reference, required this.status, required this.itemCount, required this.total, required this.createdAt});

  bool get isActive => status != OrderStatus.delivered;

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        id: json['id'] as String,
        reference: json['reference'] as String,
        status: OrderStatus.values.byName(json['status'] as String),
        itemCount: (json['itemCount'] as num).toInt(),
        total: parseAmount(json['total']),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
