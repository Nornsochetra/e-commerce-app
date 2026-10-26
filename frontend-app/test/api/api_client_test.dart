import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/models/common/page_result.dart';
import 'package:frontend_app/services/api/api_client.dart';
import 'package:frontend_app/services/api/api_exception.dart';
import 'package:frontend_app/services/api/token_storage.dart';

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

Map<String, dynamic> ok(Object? data) => {'status': {'code': 'SUCCESS', 'message': 'Success'}, 'data': data, 'common': {'requestId': 'r1', 'apiId': 'X', 'timestamp': ''}};

Map<String, dynamic> fail(String code, {List<Map<String, dynamic>> details = const []}) => {
      'status': {'code': code, 'message': 'dev text'},
      'common': {'requestId': 'r2', 'apiId': 'X', 'timestamp': ''},
      'error': {'code': code, 'type': 'X', 'message': 'dev text', 'details': details},
    };

(ApiClient, FakeAdapter, MemoryTokenStorage) client(Future<(int, Map<String, dynamic>)> Function(RequestOptions r) handler) {
  final adapter = FakeAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1', validateStatus: (_) => true))..httpClientAdapter = adapter;
  final tokens = MemoryTokenStorage();
  return (ApiClient(dio: dio, tokens: tokens), adapter, tokens);
}

const signedIn = TokenPair(accessToken: 'old-access', refreshToken: 'refresh-1');

void main() {
  test('success returns the envelope data; signed-out requests carry no token; null query values are dropped', () async {
    final (api, adapter, _) = client((r) async => (200, ok({'status': 'UP'})));
    expect(await api.get('/health', query: {'page': 0, 'query': null}, auth: false), {'status': 'UP'});
    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    expect(adapter.requests.single.uri.toString(), 'http://api.test/api/v1/health?page=0');
  });

  test('a failed envelope becomes an ApiException with a user message and field errors', () async {
    final (api, _, _) = client((r) async => (400, fail('VALIDATION_ERROR', details: [{'field': 'quantity', 'message': 'Quantity must be at least 1'}])));
    final e = await api.post('/cart/items', body: {}).then<ApiException?>((_) => null, onError: (Object e) => e as ApiException);
    expect(e!.code, 'VALIDATION_ERROR');
    expect(e.statusCode, 400);
    expect(e.requestId, 'r2');
    expect(e.fieldErrors.single.field, 'quantity');
    expect(e.userMessage, isNot(contains('dev text'))); // the server's message is never shown
  });

  test('unknown codes fall back to a generic message; 5xx gets the server-side one', () async {
    expect(const ApiException('SOMETHING_NEW', statusCode: 400).userMessage, 'Something went wrong. Please try again.');
    expect(const ApiException('SOMETHING_NEW', statusCode: 503).userMessage, contains('on our side'));
    expect(const ApiException('INSUFFICIENT_STOCK').userMessage, 'There isn’t enough stock for that quantity.');
  });

  test('no connection becomes NETWORK_ERROR', () async {
    final (api, _, _) = client((r) async => throw DioException(requestOptions: r, type: DioExceptionType.connectionError));
    await expectLater(api.get('/health', auth: false), throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiException.network).having((e) => e.isConnectionProblem, 'offline', isTrue)));
  });

  test('signed-in requests send the bearer token and extra headers', () async {
    final (api, adapter, tokens) = client((r) async => (201, ok({'id': 'o1'})));
    await tokens.save(signedIn);
    await api.post('/orders', body: {}, headers: {'Idempotency-Key': 'k-1'});
    expect(adapter.requests.single.headers['Authorization'], 'Bearer old-access');
    expect(adapter.requests.single.headers['Idempotency-Key'], 'k-1');
  });

  test('an expired access token is refreshed once, even for parallel requests, then each request is retried', () async {
    final (api, adapter, tokens) = client((r) async {
      if (r.path == '/auth/refresh') return (200, ok({'accessToken': 'new-access', 'refreshToken': 'refresh-2', 'expiresIn': 900}));
      return r.headers['Authorization'] == 'Bearer new-access' ? (200, ok({'path': r.path})) : (401, fail('INVALID_TOKEN'));
    });
    await tokens.save(signedIn);

    final results = await Future.wait([api.get('/cart'), api.get('/wishlist/items')]);
    expect(results, [{'path': '/cart'}, {'path': '/wishlist/items'}]);
    expect(adapter.requests.where((r) => r.path == '/auth/refresh'), hasLength(1));
    expect(adapter.requests.firstWhere((r) => r.path == '/auth/refresh').data, {'refreshToken': 'refresh-1'});
    expect((await tokens.read())!.refreshToken, 'refresh-2');
  });

  test('when the refresh token is rejected the tokens are cleared and the session-expired callback runs', () async {
    final (api, _, tokens) = client((r) async => r.path == '/auth/refresh' ? (401, fail('INVALID_REFRESH_TOKEN')) : (401, fail('INVALID_TOKEN')));
    await tokens.save(signedIn);
    var expired = 0;
    api.onSessionExpired = () => expired++;

    await expectLater(api.get('/cart'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'INVALID_TOKEN')));
    expect(await tokens.read(), isNull);
    expect(expired, 1);
  });

  test('being offline during a refresh keeps the tokens (nobody is signed out for a bad connection)', () async {
    final (api, _, tokens) = client((r) async {
      if (r.path == '/auth/refresh') throw DioException(requestOptions: r, type: DioExceptionType.connectionTimeout);
      return (401, fail('INVALID_TOKEN'));
    });
    await tokens.save(signedIn);
    var expired = 0;
    api.onSessionExpired = () => expired++;

    await expectLater(api.get('/cart'), throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiException.timeout)));
    expect(await tokens.read(), isNotNull);
    expect(expired, 0);
  });

  test('a 401 on a public request is not refreshed', () async {
    final (api, adapter, tokens) = client((r) async => (401, fail('INVALID_CREDENTIALS')));
    await tokens.save(signedIn);
    await expectLater(api.post('/auth/login', body: {}, auth: false), throwsA(isA<ApiException>().having((e) => e.userMessage, 'message', 'That email and password don’t match.')));
    expect(adapter.requests, hasLength(1));
    expect(await tokens.read(), isNotNull);
  });

  test('PageResult reads the Pagination shape', () {
    final page = PageResult.fromJson(
      {'items': [{'n': 1}, {'n': 2}], 'page': 0, 'size': 20, 'totalElements': 2, 'totalPages': 1, 'hasNext': false},
      (json) => json['n'] as int,
    );
    expect(page.items, [1, 2]);
    expect(page.hasNext, isFalse);
    expect(page.nextPage, 1);
  });
}
