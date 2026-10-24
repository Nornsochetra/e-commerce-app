import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/mock_data.dart';
import '../../models/cart/cart_item.dart';

/// Loads and saves the cart. Later: GET /cart, POST/PATCH/DELETE /cart/items.
class CartService {
  static const _key = 'cart_items';

  Future<List<CartItem>> getCart() async {
    await Future.delayed(mockDelay);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return mockCartItems();
    return (jsonDecode(raw) as List).map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveCart(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}
