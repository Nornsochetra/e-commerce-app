import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/mock_data.dart';
import '../../models/user/user.dart';

/// Loads and saves the customer profile. Later: GET /auth/me, PATCH /me/profile.
class UserService {
  static const _key = 'user';

  Future<User> getUser() async {
    await Future.delayed(mockDelay);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return raw == null ? mockUser() : User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }
}
