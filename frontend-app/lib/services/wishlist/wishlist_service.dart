import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/mock_data.dart';

/// Loads and saves the ids of wishlisted products. Later: GET/POST/DELETE /wishlist/items.
class WishlistService {
  static const _key = 'wishlist_ids';

  Future<List<String>> getWishlistIds() async {
    await Future.delayed(mockDelay);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return raw == null ? mockWishlistIds() : List<String>.from(jsonDecode(raw) as List);
  }

  Future<void> saveWishlistIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ids));
  }
}
