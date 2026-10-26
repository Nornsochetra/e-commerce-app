import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:frontend_app/data/mock_data.dart';
import 'package:frontend_app/models/product/product.dart';
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

class _CartLine {
  final String id;
  final String productId;
  int quantity;
  _CartLine(this.id, this.productId, this.quantity);
}

class _Account {
  final String id;
  String name;
  String email;
  String phone;
  final String password;
  final String createdAt;
  _Account(this.id, this.name, this.email, this.phone, this.password, this.createdAt);
}

/// A tiny in-memory stand-in for the auth, profile (AUT-*, USR-0401), catalog (CAT-*), cart (CRT-*) and
/// wishlist (WSH-*) endpoints, so widget tests never need the real server. It starts with the dev account
/// (as V2__seed_users.sql does), named Alex Morgan, whose cart holds 1 Minimal Watch + 2 Canvas Backpacks
/// and whose wishlist holds Classic Sunglasses and Cloud Sneakers (newest first), plus the same
/// 4 categories and 6 products as the dev catalog seed.
class FakeBackend {
  final _accounts = <_Account>[_Account('a1e00000-0000-4000-8000-000000000001', 'Alex Morgan', devAccountEmail, '+855 12 345 678', devAccountPassword, '2026-01-14T09:00:00Z')];
  final _accessTokens = <String, _Account>{};
  final _carts = <String, List<_CartLine>>{}; // account id → cart lines, oldest first
  final _wishlists = <String, List<String>>{}; // account id → product ids, newest first
  final _refreshTokens = <String, _Account>{};
  var _counter = 0;

  FakeBackend() {
    final dev = _accounts.first.id;
    _carts[dev] = [_CartLine('ci-watch', mockProducts[0].id, 1), _CartLine('ci-backpack', mockProducts[2].id, 2)];
    _wishlists[dev] = [mockProducts[4].id, mockProducts[1].id];
  }

  late final adapter = FakeAdapter(_handle);
  late final tokens = MemoryTokenStorage();
  late final client = ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://fake/api/v1', validateStatus: (_) => true))..httpClientAdapter = adapter, tokens: tokens);

  /// Signs [client] in as the dev account (for provider tests that skip the screens).
  Future<void> signIn() async {
    final data = await client.post('/auth/login', body: {'email': devAccountEmail, 'password': devAccountPassword}, auth: false);
    await tokens.save(TokenPair.fromJson(data as Map<String, dynamic>));
  }

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
    if (r.method == 'GET' && (r.path == '/categories' || r.path == '/products' || r.path.startsWith('/products/'))) return _catalog(r);
    final body = (r.data as Map<String, dynamic>?) ?? const {};
    final me = _accessTokens[(r.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '')];
    if (r.path.startsWith('/cart') || r.path.startsWith('/wishlist')) {
      if (me == null) return (401, errorEnvelope('INVALID_TOKEN'));
      return r.path.startsWith('/cart') ? _cart(r, me, body) : _wishlist(r, me, body);
    }
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

  /// GET /categories, GET /products (search, filters, sorts, paging) and GET /products/{id}.
  (int, Map<String, dynamic>) _catalog(RequestOptions r) {
    if (r.path == '/categories') {
      return (200, okEnvelope([for (final c in mockCategories) {'id': c.id, 'name': c.name, 'slug': c.slug}]));
    }
    if (r.path.startsWith('/products/')) {
      final id = r.path.substring('/products/'.length);
      final matches = mockProducts.where((p) => p.id == id);
      return matches.isEmpty ? (404, errorEnvelope('PRODUCT_NOT_FOUND')) : (200, okEnvelope(productJson(matches.first, withDescription: true)));
    }
    final q = r.queryParameters;
    final categoryId = q['categoryId'] as String?;
    if (categoryId != null && !mockCategories.any((c) => c.id == categoryId)) return (404, errorEnvelope('CATEGORY_NOT_FOUND'));
    final query = (q['query'] as String? ?? '').toLowerCase();
    var list = mockProducts
        .where((p) => (categoryId == null || p.categoryId == categoryId) && p.name.toLowerCase().contains(query) && (q['inStock'] != true || p.inStock))
        .toList();
    list = switch (q['sort'] as String? ?? 'featured,asc') {
      'price,asc' => list..sort((a, b) => a.price.compareTo(b.price)),
      'price,desc' => list..sort((a, b) => b.price.compareTo(a.price)),
      'rating,desc' => list..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0)),
      'name,asc' => list..sort((a, b) => a.name.compareTo(b.name)),
      'createdAt,desc' => list.reversed.toList(),
      _ => [...list.where((p) => p.featured), ...list.where((p) => !p.featured)],
    };
    final page = q['page'] as int? ?? 0;
    final size = q['size'] as int? ?? 20;
    final items = list.skip(page * size).take(size).toList();
    return (200, okEnvelope({
      'items': [for (final p in items) productJson(p)],
      'page': page,
      'size': size,
      'totalElements': list.length,
      'totalPages': (list.length / size).ceil(),
      'hasNext': (page + 1) * size < list.length,
    }));
  }

  /// GET /cart, POST /cart/items, PATCH and DELETE /cart/items/{itemId}; each returns the whole cart.
  (int, Map<String, dynamic>) _cart(RequestOptions r, _Account me, Map<String, dynamic> body) {
    final lines = _carts.putIfAbsent(me.id, () => []);
    Product? product(String id) => mockProducts.where((p) => p.id == id).firstOrNull;
    if (r.method == 'POST' && r.path == '/cart/items') {
      final p = product(body['productId'] as String);
      if (p == null) return (404, errorEnvelope('PRODUCT_NOT_FOUND'));
      if (!p.inStock) return (409, errorEnvelope('PRODUCT_OUT_OF_STOCK'));
      final line = lines.where((l) => l.productId == p.id).firstOrNull;
      final quantity = (line?.quantity ?? 0) + (body['quantity'] as int);
      if (quantity > p.availableQuantity) return (409, errorEnvelope('INSUFFICIENT_STOCK'));
      line == null ? lines.add(_CartLine('ci-${++_counter}', p.id, quantity)) : line.quantity = quantity;
    } else if (r.path.startsWith('/cart/items/')) {
      final line = lines.where((l) => l.id == r.path.substring('/cart/items/'.length)).firstOrNull;
      if (line == null) return (404, errorEnvelope('CART_ITEM_NOT_FOUND'));
      if (r.method == 'DELETE') {
        lines.remove(line);
      } else {
        final quantity = body['quantity'] as int;
        if (quantity > product(line.productId)!.availableQuantity) return (409, errorEnvelope('INSUFFICIENT_STOCK'));
        line.quantity = quantity;
      }
    }
    String money(double v) => v.toStringAsFixed(2);
    final items = [
      for (final l in lines)
        if (product(l.productId) case final p?)
          {
            'id': l.id,
            'product': {'id': p.id, 'name': p.name, 'imageUrl': p.imageUrl, 'availableQuantity': p.availableQuantity},
            'quantity': l.quantity,
            'unitPrice': {'amount': money(p.price), 'currency': 'USD'},
            'lineTotal': {'amount': money(p.price * l.quantity), 'currency': 'USD'},
          },
    ];
    final subtotal = lines.fold<double>(0, (sum, l) => sum + product(l.productId)!.price * l.quantity);
    return (200, okEnvelope({
      'id': lines.isEmpty ? null : 'cart-${me.id}',
      'items': items,
      'subtotal': {'amount': money(subtotal), 'currency': 'USD'},
      'itemCount': lines.fold<int>(0, (sum, l) => sum + l.quantity),
      'updatedAt': null,
    }));
  }

  /// GET /wishlist/items (newest first, paged), POST /wishlist/items, DELETE /wishlist/items/{productId}.
  (int, Map<String, dynamic>) _wishlist(RequestOptions r, _Account me, Map<String, dynamic> body) {
    final ids = _wishlists.putIfAbsent(me.id, () => []);
    if (r.method == 'POST') {
      final p = mockProducts.where((p) => p.id == body['productId']).firstOrNull;
      if (p == null) return (404, errorEnvelope('PRODUCT_NOT_FOUND'));
      final isNew = !ids.contains(p.id);
      if (isNew) ids.insert(0, p.id);
      return (isNew ? 201 : 200, okEnvelope(productJson(p)));
    }
    if (r.method == 'DELETE') {
      if (!ids.remove(r.path.substring('/wishlist/items/'.length))) return (404, errorEnvelope('WISHLIST_ITEM_NOT_FOUND'));
      return (200, okEnvelope(<String, dynamic>{}));
    }
    final page = r.queryParameters['page'] as int? ?? 0;
    final size = r.queryParameters['size'] as int? ?? 20;
    final saved = [for (final id in ids) mockProducts.firstWhere((p) => p.id == id)];
    return (200, okEnvelope({
      'items': [for (final p in saved.skip(page * size).take(size)) productJson(p)],
      'page': page,
      'size': size,
      'totalElements': saved.length,
      'totalPages': (saved.length / size).ceil(),
      'hasNext': (page + 1) * size < saved.length,
    }));
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

/// A product as the API sends it: money as a decimal string, rating as a string, badges lowercase,
/// and the description only on product details.
Map<String, dynamic> productJson(Product p, {bool withDescription = false}) => {
      'id': p.id,
      'name': p.name,
      if (withDescription) 'description': p.description,
      'category': {'id': p.categoryId, 'name': p.categoryName},
      'price': {'amount': p.price.toStringAsFixed(2), 'currency': 'USD'},
      'availableQuantity': p.availableQuantity,
      'rating': p.rating?.toStringAsFixed(1),
      'imageUrl': p.imageUrl,
      'badges': [for (final b in p.badges.reversed) b.toLowerCase()], // the real API doesn't keep the order either
      'featured': p.featured,
    };
