import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Talks to the Spring API. Services call [get], [post], [patch] and [delete]; this class
///  - sends `Authorization: Bearer <access token>` when signed in,
///  - unwraps the `ApiResponse` envelope and returns its `data`,
///  - turns every failure into an [ApiException] (with a user-facing message),
///  - refreshes the tokens shortly before the access token expires (so public catalog reads keep
///    knowing who is signed in), and if a request still gets HTTP 401, refreshes once and retries it.
///    If the refresh token is no longer valid either, the tokens are cleared and [onSessionExpired] runs.
///
/// The whole app shares [instance], so all requests use the same tokens and only one refresh runs at a time.
class ApiClient {
  static ApiClient instance = ApiClient();

  final Dio _dio;
  final TokenStorage tokens;

  /// Called after the session could not be refreshed (set by AuthProvider to sign the user out).
  void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  ApiClient({Dio? dio, TokenStorage? tokens})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
              validateStatus: (_) => true, // every status is handled in _send
            )),
        tokens = tokens ?? SecureTokenStorage();

  /// [auth] false skips the token for public endpoints (login, catalog reads, …).
  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async => (await _send('GET', path, query: query, auth: auth)).$1;

  Future<dynamic> post(String path, {Object? body, Map<String, String>? headers, bool auth = true}) async =>
      (await _send('POST', path, body: body, headers: headers, auth: auth)).$1;

  /// Like [post], also returning the HTTP status (e.g. 201 newly created vs 200 already there).
  Future<(dynamic, int)> postWithStatus(String path, {Object? body, bool auth = true}) => _send('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) async => (await _send('PATCH', path, body: body, auth: auth)).$1;

  Future<dynamic> delete(String path, {bool auth = true}) async => (await _send('DELETE', path, auth: auth)).$1;

  Future<(dynamic, int)> _send(String method, String path, {Map<String, dynamic>? query, Object? body, Map<String, String>? headers, required bool auth}) async {
    var token = auth ? (await tokens.read())?.accessToken : null;
    if (token != null && _expiresSoon(token)) {
      try {
        if (await _refreshTokens()) token = (await tokens.read())?.accessToken;
      } on ApiException {
        // Offline: send the request anyway; a 401 below is handled as usual.
      }
    }
    try {
      return await _request(method, path, query: query, body: body, headers: headers, token: token);
    } on ApiException catch (e) {
      final expired = e.statusCode == 401 && token != null;
      if (!expired) rethrow;
      if (!await _refreshTokens()) {
        await tokens.clear();
        onSessionExpired?.call();
        rethrow;
      }
      final fresh = (await tokens.read())?.accessToken;
      return _request(method, path, query: query, body: body, headers: headers, token: fresh);
    }
  }

  Future<(dynamic, int)> _request(String method, String path, {Map<String, dynamic>? query, Object? body, Map<String, String>? headers, String? token}) async {
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query == null ? null : {for (final e in query.entries) if (e.value != null) e.key: e.value},
        options: Options(method: method, headers: {...?headers, 'Authorization': ?(token == null ? null : 'Bearer $token')}),
      );
    } on DioException catch (e) {
      final timedOut = e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout;
      throw ApiException(timedOut ? ApiException.timeout : ApiException.network, debugMessage: e.message);
    }

    final status = response.statusCode ?? 0;
    final envelope = response.data;
    if (envelope is! Map<String, dynamic>) {
      throw ApiException(status >= 500 ? 'INTERNAL_ERROR' : 'INVALID_REQUEST', statusCode: status, debugMessage: 'Response is not an ApiResponse envelope');
    }
    if (status >= 200 && status < 300) return (envelope['data'], status);
    throw ApiException.fromEnvelope(envelope, statusCode: status);
  }

  /// Exchanges the refresh token for a new pair. Concurrent callers wait for the same refresh.
  /// Returns false when there is no valid refresh token (the user must sign in again).
  /// Connection problems are rethrown, so being offline never signs anyone out.
  /// True when the JWT's `exp` is less than a minute away. Tokens that can't be read count as fine
  /// (the server decides; a 401 still triggers a refresh).
  static bool _expiresSoon(String jwt) {
    try {
      final payload = jwt.split('.')[1];
      final claims = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload)))) as Map<String, dynamic>;
      final exp = DateTime.fromMillisecondsSinceEpoch((claims['exp'] as num).toInt() * 1000);
      return exp.difference(DateTime.now()) < const Duration(minutes: 1);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _refreshTokens() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final current = await tokens.read();
    if (current == null) return false;
    try {
      final (data, _) = await _request('POST', '/auth/refresh', body: {'refreshToken': current.refreshToken});
      await tokens.save(TokenPair.fromJson(data as Map<String, dynamic>));
      return true;
    } on ApiException catch (e) {
      if (e.isConnectionProblem) rethrow;
      return false;
    }
  }
}
