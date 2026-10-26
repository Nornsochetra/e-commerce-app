import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:frontend_app/services/api/api_client.dart';
import 'package:frontend_app/services/api/token_storage.dart';
import 'package:frontend_app/services/auth/dev_account.dart';

/// Answers requests with [handler] instead of the network, and remembers every request.
class FakeAdapter implements HttpClientAdapter {
  final Future<(int, Map<String, dynamic>)> Function(RequestOptions request) handler;
  final requests = <RequestOptions>[];
  FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final (status, body) = await handler(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// `ApiResponse` envelopes, as the Spring backend sends them.
Map<String, dynamic> okEnvelope(Object? data) => {'status': {'code': 'SUCCESS', 'message': 'Success'}, 'data': data, 'common': {'requestId': 'r1', 'apiId': 'X', 'timestamp': ''}};

Map<String, dynamic> errorEnvelope(String code, {List<Map<String, dynamic>> details = const []}) => {
      'status': {'code': code, 'message': 'dev text'},
      'common': {'requestId': 'r2', 'apiId': 'X', 'timestamp': ''},
      'error': {'code': code, 'type': 'X', 'message': 'dev text', 'details': details},
    };

class _Account {
  final String id;
  String name;
  String email;
  String phone;
  final String password;
  final String createdAt;
  _Account(this.id, this.name, this.email, this.phone, this.password, this.createdAt);
}

/// A tiny in-memory stand-in for the auth and profile endpoints (AUT-*, USR-0401), so widget tests
/// never need the real server. It starts with the dev account (as V2__seed_users.sql does), named Alex Morgan.
class FakeBackend {
  final _accounts = <_Account>[_Account('a1e00000-0000-4000-8000-000000000001', 'Alex Morgan', devAccountEmail, '+855 12 345 678', devAccountPassword, '2026-01-14T09:00:00Z')];
  final _accessTokens = <String, _Account>{};
  final _refreshTokens = <String, _Account>{};
  var _counter = 0;

  late final adapter = FakeAdapter(_handle);
  late final tokens = MemoryTokenStorage();
  late final client = ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://fake/api/v1', validateStatus: (_) => true))..httpClientAdapter = adapter, tokens: tokens);

  /// When true, every request fails as if the phone had no connection.
  bool offline = false;

  /// Adds another registered account (e.g. to test "email already in use").
  void addAccount({required String name, required String email, String password = 'Passw0rd!'}) =>
      _accounts.add(_Account('u-${++_counter}', name, email, '', password, '2026-02-01T00:00:00Z'));

  /// Makes every current access token invalid, like the 15-minute expiry (refresh tokens still work).
  void expireAccessTokens() => _accessTokens.clear();

  /// Makes every token invalid, like a logout on another device.
  void revokeAllTokens() {
    _accessTokens.clear();
    _refreshTokens.clear();
  }

  int calls(String method, String path) => adapter.requests.where((r) => r.method == method && r.path == path).length;

  Future<(int, Map<String, dynamic>)> _handle(RequestOptions r) async {
    if (offline) throw DioException(requestOptions: r, type: DioExceptionType.connectionError);
    final body = (r.data as Map<String, dynamic>?) ?? const {};
    final me = _accessTokens[(r.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '')];
    switch ('${r.method} ${r.path}') {
      case 'POST /auth/login':
        final account = _find(body['email'] as String);
        if (account == null || account.password != body['password']) return (401, errorEnvelope('INVALID_CREDENTIALS'));
        return (200, okEnvelope(_session(account)));
      case 'POST /auth/register':
        if (_find(body['email'] as String) != null) return (409, errorEnvelope('EMAIL_ALREADY_REGISTERED'));
        final account = _Account('u-${++_counter}', body['name'] as String, (body['email'] as String).toLowerCase(), '', body['password'] as String, '2026-10-26T00:00:00Z');
        _accounts.add(account);
        return (201, okEnvelope(_session(account)));
      case 'POST /auth/refresh':
        final account = _refreshTokens[body['refreshToken']];
        if (account == null) return (401, errorEnvelope('INVALID_REFRESH_TOKEN'));
        return (200, okEnvelope(_session(account)..remove('user')));
      case 'POST /auth/forgot-password':
        return (200, okEnvelope(<String, dynamic>{}));
      case 'POST /auth/logout':
        if (me == null) return (401, errorEnvelope('INVALID_TOKEN'));
        _accessTokens.removeWhere((_, a) => a == me);
        _refreshTokens.removeWhere((_, a) => a == me);
        return (200, okEnvelope(<String, dynamic>{}));
      case 'GET /auth/me':
        if (me == null) return (401, errorEnvelope('INVALID_TOKEN'));
        return (200, okEnvelope(_currentUser(me)));
      case 'PATCH /me/profile':
        if (me == null) return (401, errorEnvelope('INVALID_TOKEN'));
        final email = (body['email'] as String?)?.toLowerCase();
        if (email != null && _accounts.any((a) => a != me && a.email == email)) return (409, errorEnvelope('EMAIL_ALREADY_REGISTERED'));
        me.name = body['name'] as String? ?? me.name;
        me.email = email ?? me.email;
        me.phone = body['phone'] as String? ?? me.phone;
        return (200, okEnvelope(_currentUser(me)));
    }
    return (404, errorEnvelope('NOT_FOUND'));
  }

  _Account? _find(String email) {
    for (final a in _accounts) {
      if (a.email == email.trim().toLowerCase()) return a;
    }
    return null;
  }

  Map<String, dynamic> _session(_Account a) {
    final access = 'access-${++_counter}';
    final refresh = 'refresh-${++_counter}';
    _accessTokens[access] = a;
    _refreshTokens[refresh] = a;
    return {'accessToken': access, 'refreshToken': refresh, 'expiresIn': 900, 'user': {'id': a.id, 'name': a.name, 'email': a.email, 'phone': a.phone.isEmpty ? null : a.phone, 'role': 'user'}};
  }

  Map<String, dynamic> _currentUser(_Account a) => {
        'id': a.id,
        'name': a.name,
        'email': a.email,
        'phone': a.phone.isEmpty ? null : a.phone,
        'role': 'user',
        'memberSince': a.createdAt,
        'counts': {'orders': 0, 'wishlistItems': 0, 'cartItems': 0},
        'createdAt': a.createdAt,
        'updatedAt': a.createdAt,
      };
}
