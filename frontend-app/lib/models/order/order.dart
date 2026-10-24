import 'order_item.dart';

/// Order status flow: pending → confirmed → shipped → delivered.
enum OrderStatus { pending, confirmed, shipped, delivered }

/// A placed order.
class Order {
  final String id;
  final String reference; // e.g. MC-19842
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

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        reference: json['reference'] as String,
        status: OrderStatus.values.byName(json['status'] as String),
        items: (json['items'] as List).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
        recipientName: json['recipientName'] as String,
        email: json['email'] as String,
        address: json['address'] as String,
        paymentMethod: json['paymentMethod'] as String? ?? 'cash_on_delivery',
        subtotal: (json['subtotal'] as num).toDouble(),
        deliveryFee: (json['deliveryFee'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'status': status.name,
        'items': items.map((e) => e.toJson()).toList(),
        'recipientName': recipientName,
        'email': email,
        'address': address,
        'paymentMethod': paymentMethod,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
