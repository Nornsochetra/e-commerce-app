import 'package:frontend_app/models/product/category.dart';
import 'package:frontend_app/models/product/product.dart';

/// The sample catalog the fake backend serves in widget tests: the same 4 categories and 6 products
/// (and UUIDs) as the backend's dev seed (backend/src/main/resources/db/dev/R__dev_seed_catalog.sql).

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
