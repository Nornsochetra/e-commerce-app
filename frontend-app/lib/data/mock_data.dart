import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart/cart_item.dart';
import '../models/notification/app_notification.dart';
import '../models/order/order.dart';
import '../models/order/order_item.dart';
import '../models/product/category.dart';
import '../models/product/product.dart';
import '../models/user/user.dart';

/// Sample data used until the app is connected to the Spring backend.
/// Same products, orders and notifications as the HTML prototype.

/// Pretend network delay used by every mock service call.
const mockDelay = Duration(milliseconds: 300);

/// Demo sign-in (also shown on the login screen).
const demoEmail = 'demo@mercato.app';
const demoPassword = 'Demo123!';

/// Flat standard delivery fee (USD), as in the requirements.
const deliveryFeeUsd = 4.0;

/// Product photos come from the API in the real app, so the mock uses the same URLs as the prototype.
String _image(String id) => 'https://images.unsplash.com/photo-$id?auto=format&fit=crop&w=800&q=80';

const mockCategories = [
  Category(id: 'a0000000-0000-4000-8000-000000000001', name: 'Accessories', slug: 'accessories'),
  Category(id: 'a0000000-0000-4000-8000-000000000002', name: 'Footwear', slug: 'footwear'),
  Category(id: 'a0000000-0000-4000-8000-000000000003', name: 'Bags', slug: 'bags'),
  Category(id: 'a0000000-0000-4000-8000-000000000004', name: 'Electronics', slug: 'electronics'),
];

final mockProducts = [
  Product(
    id: '11111111-1111-4111-8111-111111111111',
    name: 'Minimal Watch',
    description: 'A quiet, refined watch designed for everyday wear.',
    categoryId: mockCategories[0].id,
    categoryName: 'Accessories',
    price: 89,
    availableQuantity: 8,
    rating: 4.8,
    imageUrl: _image('1523275335684-37898b6baf30'),
    badges: const ['NEW', 'PREMIUM_PICK'],
    featured: true,
  ),
  Product(
    id: '22222222-2222-4222-8222-222222222222',
    name: 'Cloud Sneakers',
    categoryId: mockCategories[1].id,
    categoryName: 'Footwear',
    price: 74,
    availableQuantity: 12,
    rating: 4.6,
    imageUrl: _image('1542291026-7eec264c27ff'),
    badges: const ['BESTSELLER'],
    featured: true,
  ),
  Product(
    id: '33333333-3333-4333-8333-333333333333',
    name: 'Canvas Backpack',
    description: 'Durable canvas storage with a comfortable everyday silhouette.',
    categoryId: mockCategories[2].id,
    categoryName: 'Bags',
    price: 58,
    availableQuantity: 5,
    rating: 4.7,
    imageUrl: _image('1553062407-98eeb64c6a62'),
    badges: const ['BESTSELLER'],
    featured: true,
  ),
  Product(
    id: '44444444-4444-4444-8444-444444444444',
    name: 'Studio Headphones',
    description: 'Immersive sound with a lightweight over-ear design.',
    categoryId: mockCategories[3].id,
    categoryName: 'Electronics',
    price: 129,
    availableQuantity: 0,
    rating: 4.9,
    imageUrl: _image('1505740420928-5e560c06d30e'),
    badges: const ['PREMIUM_PICK'],
  ),
  Product(
    id: '55555555-5555-4555-8555-555555555555',
    name: 'Classic Sunglasses',
    categoryId: mockCategories[0].id,
    categoryName: 'Accessories',
    price: 42,
    availableQuantity: 16,
    rating: 4.5,
    imageUrl: _image('1511499767150-a48a237f0083'),
  ),
  Product(
    id: '66666666-6666-4666-8666-666666666666',
    name: 'Everyday Camera',
    description: 'A compact camera for documenting the moments that matter.',
    categoryId: mockCategories[3].id,
    categoryName: 'Electronics',
    price: 245,
    availableQuantity: 3,
    rating: 4.7,
    imageUrl: _image('1516035069371-29a1b244cc32'),
    badges: const ['NEW'],
    featured: true,
  ),
];

CartItem _cartItem(Product p, int quantity) => CartItem(
      productId: p.id,
      name: p.name,
      imageUrl: p.imageUrl,
      categoryName: p.categoryName,
      unitPrice: p.price,
      quantity: quantity,
      availableQuantity: p.availableQuantity,
    );

OrderItem _orderItem(Product p, int quantity) =>
    OrderItem(productId: p.id, name: p.name, imageUrl: p.imageUrl, unitPrice: p.price, quantity: quantity);

/// Starting cart: 1 watch + 2 backpacks.
List<CartItem> mockCartItems() => [_cartItem(mockProducts[0], 1), _cartItem(mockProducts[2], 2)];

/// Starting wishlist: sneakers + sunglasses.
List<String> mockWishlistIds() => [mockProducts[1].id, mockProducts[4].id];

User mockUser() => User(
      id: 'a1e00000-0000-4000-8000-000000000001',
      name: 'Alex Morgan',
      email: 'alex@example.com',
      phone: '+855 12 345 678',
      memberSince: DateTime.utc(2026, 1, 14),
    );

/// Two sample orders, dated relative to today.
List<Order> mockOrders() {
  final now = DateTime.now();
  return [
    Order(
      id: 'd1984200-0000-4000-8000-000000000002',
      reference: 'MC-19842',
      status: OrderStatus.shipped,
      items: [_orderItem(mockProducts[1], 1)],
      recipientName: 'Alex Morgan',
      email: 'alex@example.com',
      address: '12 Riverside Street, Phnom Penh',
      subtotal: 74,
      deliveryFee: deliveryFeeUsd,
      total: 78,
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
    Order(
      id: 'd2048100-0000-4000-8000-000000000001',
      reference: 'MC-20481',
      status: OrderStatus.delivered,
      items: [_orderItem(mockProducts[0], 1), _orderItem(mockProducts[2], 2)],
      recipientName: 'Alex Morgan',
      email: 'alex@example.com',
      address: '12 Riverside Street, Phnom Penh',
      subtotal: 205,
      deliveryFee: deliveryFeeUsd,
      total: 209,
      createdAt: now.subtract(const Duration(days: 14)),
      updatedAt: now.subtract(const Duration(days: 11)),
    ),
  ];
}

/// Four sample notifications (two unread), dated relative to now.
List<AppNotification> mockNotifications() {
  final now = DateTime.now();
  return [
    AppNotification(
      id: 'a1111111-1111-4111-8111-111111111111',
      type: NotificationType.order,
      title: 'Your order is on the way',
      message: 'Order #MC-19842 has shipped and is moving toward Phnom Penh.',
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'b2222222-2222-4222-8222-222222222222',
      type: NotificationType.offer,
      title: 'A little something for you',
      message: 'Enjoy free standard delivery on your next mock order.',
      createdAt: now.subtract(const Duration(hours: 5)),
    ),
    AppNotification(
      id: 'c3333333-3333-4333-8333-333333333333',
      type: NotificationType.stock,
      title: 'Back in stock',
      message: 'Cloud Sneakers from your wishlist are available again.',
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      readAt: now.subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: 'd4444444-4444-4444-8444-444444444444',
      type: NotificationType.order,
      title: 'Order delivered',
      message: 'Order #MC-20481 was delivered. We hope you enjoy it.',
      createdAt: now.subtract(const Duration(days: 12, hours: 1)),
      readAt: now.subtract(const Duration(days: 12)),
    ),
  ];
}

/// Deletes everything the mock services saved, so the app starts fresh (Profile → Reset demo data).
Future<void> resetDemoData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}
