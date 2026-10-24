import 'package:shared_preferences/shared_preferences.dart';

import '../../data/mock_data.dart';
import '../../models/user/user.dart';
import '../user/user_service.dart';

/// Sign-in state saved on the device.
enum SessionType { signedIn, guest }

/// Thrown when sign-in fails; [message] is safe to show to the user.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

/// Signs users in and out. Mock: accepts only the demo account.
/// Later: POST /auth/login, /auth/register, /auth/logout, /auth/forgot-password.
class AuthService {
  static const _sessionKey = 'session';
  final _userService = UserService();

  /// The saved session, or null when signed out.
  Future<SessionType?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_sessionKey);
    return value == null ? null : SessionType.values.byName(value);
  }

  Future<void> login(String email, String password) async {
    await Future.delayed(mockDelay);
    if (email.trim().toLowerCase() != demoEmail || password != demoPassword) {
      throw const AuthException('That email and password don’t match. Use the demo account, or continue as a guest.');
    }
    await _saveSession(SessionType.signedIn);
  }

  /// Creates the account and signs in immediately (no email verification in v1).
  Future<void> register({required String name, required String email, required String phone, required String password}) async {
    await Future.delayed(mockDelay);
    final current = await _userService.getUser();
    final user = User(id: current.id, name: name.trim(), email: email.trim().toLowerCase(), phone: phone.trim(), memberSince: DateTime.now());
    await _userService.saveUser(user);
    await _saveSession(SessionType.signedIn);
  }

  Future<void> continueAsGuest() => _saveSession(SessionType.guest);

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// Always succeeds, so the app never reveals whether an account exists.
  Future<void> requestPasswordReset(String email) => Future.delayed(mockDelay);

  Future<void> _saveSession(SessionType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, type.name);
  }
}
