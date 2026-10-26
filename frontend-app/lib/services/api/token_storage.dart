import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The access and refresh tokens from login, register or refresh.
class TokenPair {
  final String accessToken;
  final String refreshToken;
  const TokenPair({required this.accessToken, required this.refreshToken});

  factory TokenPair.fromJson(Map<String, dynamic> json) =>
      TokenPair(accessToken: json['accessToken'] as String, refreshToken: json['refreshToken'] as String);
}

/// Keeps the tokens between app starts. Tokens are credentials, so they go to the Keychain (iOS) /
/// Keystore (Android) instead of shared_preferences.
abstract class TokenStorage {
  Future<TokenPair?> read();
  Future<void> save(TokenPair tokens);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  static const _access = 'access_token';
  static const _refresh = 'refresh_token';
  final _storage = const FlutterSecureStorage();

  @override
  Future<TokenPair?> read() async {
    final access = await _storage.read(key: _access);
    final refresh = await _storage.read(key: _refresh);
    if (access == null || refresh == null) return null;
    return TokenPair(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> save(TokenPair tokens) async {
    await _storage.write(key: _access, value: tokens.accessToken);
    await _storage.write(key: _refresh, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }
}

/// Keeps tokens in memory only (widget tests).
class MemoryTokenStorage implements TokenStorage {
  TokenPair? _tokens;

  @override
  Future<TokenPair?> read() async => _tokens;

  @override
  Future<void> save(TokenPair tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
