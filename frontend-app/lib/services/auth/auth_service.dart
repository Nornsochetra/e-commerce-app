import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/token_storage.dart';

/// How the app was left last time.
enum SessionType { signedIn, guest }

/// Signs users in and out and changes the password through the API (AUT-0201 … AUT-0206).
/// The tokens are kept by [ApiClient.tokens]; "continue as guest" is only a flag on this device.
/// Failures throw [ApiException]; show its `userMessage`.
class AuthService {
  static const _guestKey = 'guest_session';
  final ApiClient _api;

  AuthService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  /// Signed in when tokens are saved, guest when the user chose that, otherwise null (signed out).
  /// Whether the tokens still work is found out by the first request (it refreshes or signs out).
  Future<SessionType?> getSession() async {
    if (await _api.tokens.read() != null) return SessionType.signedIn;
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(_guestKey) ?? false) ? SessionType.guest : null;
  }

  Future<void> login(String email, String password) async {
    final data = await _api.post('/auth/login', body: {'email': email.trim(), 'password': password}, auth: false);
    await _startSession(data as Map<String, dynamic>);
  }

  /// Creates the account and signs in right away (no email verification in v1).
  /// The register endpoint has no phone field, so a phone number is saved with a profile update afterwards.
  /// If only that second step fails, the account still exists and the user is signed in.
  Future<void> register({required String name, required String email, required String phone, required String password}) async {
    final data = await _api.post('/auth/register', body: {'name': name.trim(), 'email': email.trim(), 'password': password}, auth: false);
    await _startSession(data as Map<String, dynamic>);
    if (phone.trim().isEmpty) return;
    try {
      await _api.patch('/me/profile', body: {'phone': phone.trim()});
    } on ApiException {
      // The phone can be added later on Profile.
    }
  }

  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, true);
  }

  /// Revokes every token of the account on the server, then forgets them here.
  /// Signing out always works locally, even when the server can't be reached.
  Future<void> logout() async {
    try {
      if (await _api.tokens.read() != null) await _api.post('/auth/logout');
    } on ApiException {
      // Offline or already expired: the local sign-out below is what matters.
    }
    await _api.tokens.clear();
  }

  /// Changes the password. The server signs out every other device and sends a new token pair,
  /// which replaces the old one so this device stays signed in.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final data = await _api.post('/auth/change-password', body: {'currentPassword': currentPassword, 'newPassword': newPassword});
    await _api.tokens.save(TokenPair.fromJson(data as Map<String, dynamic>));
  }

  Future<void> _startSession(Map<String, dynamic> data) async {
    await _api.tokens.save(TokenPair.fromJson(data));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
  }
}
