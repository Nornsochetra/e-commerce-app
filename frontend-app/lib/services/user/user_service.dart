import '../../models/user/user.dart';
import '../api/api_client.dart';

/// The signed-in customer's profile: GET /auth/me (AUT-0601) and PATCH /me/profile (USR-0401).
/// Failures throw ApiException.
class UserService {
  final ApiClient _api;
  UserService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  Future<User> getUser() async => User.fromJson(await _api.get('/auth/me') as Map<String, dynamic>);

  /// Saves name, email and phone. An empty phone clears it; name and email can't be cleared.
  Future<User> updateProfile({required String name, required String email, required String phone}) async {
    final data = await _api.patch('/me/profile', body: {'name': name.trim(), 'email': email.trim(), 'phone': phone.trim()});
    return User.fromJson(data as Map<String, dynamic>);
  }
}
