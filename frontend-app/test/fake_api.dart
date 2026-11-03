import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:frontend_app/models/product/product.dart';
import 'package:frontend_app/services/api/api_client.dart';
import 'package:frontend_app/services/api/token_storage.dart';
import 'package:frontend_app/services/auth/dev_account.dart';

import 'fake_catalog.dart';

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
  String password;
  final String createdAt;
  _Account(this.id, this.name, this.email, this.phone, this.password, this.createdAt);
}

/// A tiny in-memory stand-in for the auth, profile (AUT-*, USR-0401), catalog (CAT-*), cart (CRT-*) and
/// wishlist (WSH-*) endpoints, so widget tests never need the real server. It starts with the dev account
/// (as V2__seed_users.sql does), named Alex Morgan, whose cart holds 1 Minimal Watch + 2 Canvas Backpacks
/// and whose wishlist holds Classic Sunglasses and Cloud Sneakers (newest first), with orders MC-19842
/// (shipped) and MC-20481 (delivered) and 4 notifications (2 unread); plus the same 4 categories and
/// 6 products as the dev catalog seed. Also serves orders (ORD-*) and notifications (NTF-*).
class FakeBackend {
  final _accounts = <_Account>[_Account('a1e00000-0000-4000-8000-000000000001', 'Alex Morgan', devAccountEmail, '+855 12 345 678', devAccountPassword, '2026-01-14T09:00:00Z')];
  final _accessTokens = <String, _Account>{};
  final _carts = <String, List<_CartLine>>{}; // account id → cart lines, oldest first
  final _wishlists = <String, List<String>>{}; // account id → product ids, newest first
  final _orderStore = <String, List<Map<String, dynamic>>>{}; // account id → orders as the API sends them, newest first
  final _notificationStore = <String, List<Map<String, dynamic>>>{}; // account id → notifications, newest first
  final _idempotency = <String, (String, String)>{}; // Idempotency-Key → (request body, order id)
  final _refreshTokens = <String, _Account>{};
  var _counter = 0;

  FakeBackend() {
    final dev = _accounts.first.id;
    _carts[dev] = [_CartLine('ci-watch', mockProducts[0].id, 1), _CartLine('ci-backpack', mockProducts[2].id, 2)];
    _wishlists[dev] = [mockProducts[4].id, mockProducts[1].id];
    _seedOrdersAndNotifications(dev);
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
    final body = (r.data as Map<String, dynamic>?) ?? const {};
    final me = _accessTokens[(r.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '')];
    // Catalog reads are public; with a valid token each product says whether that user saved it.
    if (r.method == 'GET' && (r.path == '/categories' || r.path == '/products' || r.path.startsWith('/products/'))) return _catalog(r, me);
    if (r.path.startsWith('/cart') || r.path.startsWith('/wishlist') || r.path.startsWith('/orders') || r.path.startsWith('/notifications')) {
      if (me == null) return (401, errorEnvelope('INVALID_TOKEN'));
      if (r.path.startsWith('/orders')) return _orders(r, me, body);
      if (r.path.startsWith('/notifications')) return _notifications(r, me);
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
      case 'POST /auth/change-password':
        if (me == null) return (401, errorEnvelope('INVALID_TOKEN'));
        if (body['currentPassword'] != me.password) return (400, errorEnvelope('CURRENT_PASSWORD_INCORRECT'));
        me.password = body['newPassword'] as String;
        // Like the token version bump: every older token of the account stops working.
        _accessTokens.removeWhere((_, a) => a == me);
        _refreshTokens.removeWhere((_, a) => a == me);
        return (200, okEnvelope(_session(me)..remove('user')));
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
  (int, Map<String, dynamic>) _catalog(RequestOptions r, _Account? me) {
    final savedIds = me == null ? const <String>[] : (_wishlists[me.id] ?? const <String>[]);
    if (r.path == '/categories') {
      return (200, okEnvelope([for (final c in mockCategories) {'id': c.id, 'name': c.name, 'slug': c.slug}]));
    }
    if (r.path.startsWith('/products/')) {
      final id = r.path.substring('/products/'.length);
      final matches = mockProducts.where((p) => p.id == id);
      return matches.isEmpty ? (404, errorEnvelope('PRODUCT_NOT_FOUND')) : (200, okEnvelope(productJson(matches.first, withDescription: true, saved: savedIds.contains(matches.first.id))));
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
      'items': [for (final p in items) productJson(p, saved: savedIds.contains(p.id))],
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
      return (isNew ? 201 : 200, okEnvelope(productJson(p, saved: true)));
    }
    if (r.method == 'DELETE') {
      if (!ids.remove(r.path.substring('/wishlist/items/'.length))) return (404, errorEnvelope('WISHLIST_ITEM_NOT_FOUND'));
      return (200, okEnvelope(<String, dynamic>{}));
    }
    final page = r.queryParameters['page'] as int? ?? 0;
    final size = r.queryParameters['size'] as int? ?? 20;
    final saved = [for (final id in ids) mockProducts.firstWhere((p) => p.id == id)];
    return (200, okEnvelope({
      'items': [for (final p in saved.skip(page * size).take(size)) productJson(p, saved: true)],
      'page': page,
      'size': size,
      'totalElements': saved.length,
      'totalPages': (saved.length / size).ceil(),
      'hasNext': (page + 1) * size < saved.length,
    }));
  }

  /// POST /orders/preview, POST /orders (Idempotency-Key), GET /orders, GET /orders/{id}.
  (int, Map<String, dynamic>) _orders(RequestOptions r, _Account me, Map<String, dynamic> body) {
    final orders = _orderStore.putIfAbsent(me.id, () => []);
    String money(double v) => v.toStringAsFixed(2);
    Map<String, dynamic> amount(double v) => {'amount': money(v), 'currency': 'USD'};

    if (r.method == 'POST') {
      final lines = _carts.putIfAbsent(me.id, () => []);
      // Like the real API, a replayed Idempotency-Key is answered before the cart is checked.
      final replayKey = r.path == '/orders' ? r.headers['Idempotency-Key'] as String? : null;
      final replayOf = replayKey == null ? null : _idempotency[replayKey];
      if (replayOf != null) {
        if (replayOf.$1 != jsonEncode(body)) return (409, errorEnvelope('CONFLICT'));
        return (201, okEnvelope(orders.firstWhere((o) => o['id'] == replayOf.$2)));
      }
      final delivery = (body['delivery'] as Map<String, dynamic>?) ?? const {};
      if (lines.isEmpty) return (409, errorEnvelope('CART_EMPTY'));
      if ([delivery['recipientName'], delivery['email'], delivery['address']].any((v) => v == null || (v as String).trim().isEmpty)) {
        return (400, errorEnvelope('CHECKOUT_INVALID'));
      }
      final products = {for (final p in mockProducts) p.id: p};
      if (lines.any((l) => l.quantity > products[l.productId]!.availableQuantity)) return (409, errorEnvelope('INSUFFICIENT_STOCK'));
      final items = [
        for (final l in lines)
          {
            'productId': l.productId,
            'name': products[l.productId]!.name,
            'quantity': l.quantity,
            'unitPrice': amount(products[l.productId]!.price),
            'lineTotal': amount(products[l.productId]!.price * l.quantity),
          },
      ];
      final subtotal = lines.fold<double>(0, (sum, l) => sum + products[l.productId]!.price * l.quantity);

      if (r.path == '/orders/preview') {
        return (200, okEnvelope({
          'items': [for (final (i, item) in items.indexed) {...item, 'imageUrl': products[lines[i].productId]!.imageUrl}],
          'deliveryMethod': 'standard',
          'estimatedDelivery': '2–4 business days',
          'subtotal': amount(subtotal),
          'deliveryFee': amount(4),
          'total': amount(subtotal + 4),
          'expiresAt': null,
        }));
      }

      final key = r.headers['Idempotency-Key'] as String?;
      if (key == null) return (400, errorEnvelope('VALIDATION_ERROR'));
      final payload = jsonEncode(body);
      final now = DateTime.now().toUtc().toIso8601String();
      final order = {
        'id': 'o-${++_counter}',
        'reference': 'MC-${(0xA1B2C3D4E5F0 + _counter).toRadixString(16).toUpperCase()}',
        'status': 'pending',
        'items': items,
        'delivery': {'recipientName': delivery['recipientName'], 'email': delivery['email'], 'address': delivery['address']},
        'deliveryMethod': 'standard',
        'estimatedDelivery': '2–4 business days',
        'paymentMethod': 'cash_on_delivery',
        'subtotal': amount(subtotal),
        'deliveryFee': amount(4),
        'total': amount(subtotal + 4),
        'createdAt': now,
        'updatedAt': now,
      };
      orders.insert(0, order);
      _idempotency[key] = (payload, order['id'] as String);
      lines.clear(); // the ordered items leave the cart
      _notificationStore.putIfAbsent(me.id, () => []).insert(0, {
        'id': 'n-${++_counter}',
        'type': 'order',
        'title': 'Order placed',
        'message': 'Order #${order['reference']} has been placed successfully.',
        'readAt': null,
        'createdAt': now,
      });
      return (201, okEnvelope(order));
    }

    if (r.path.startsWith('/orders/')) {
      final order = orders.where((o) => o['id'] == r.path.substring('/orders/'.length)).firstOrNull;
      return order == null ? (404, errorEnvelope('ORDER_NOT_FOUND')) : (200, okEnvelope(order));
    }
    final summaries = [
      for (final o in orders)
        {
          'id': o['id'],
          'reference': o['reference'],
          'status': o['status'],
          'itemCount': (o['items'] as List).fold<int>(0, (sum, i) => sum + (i['quantity'] as int)),
          'total': o['total'],
          'createdAt': o['createdAt'],
        },
    ];
    return (200, okEnvelope(_page(summaries, r)));
  }

  /// GET /notifications (paged), GET /notifications/unread-count, POST …/{id}/read, POST …/read-all, DELETE /notifications.
  (int, Map<String, dynamic>) _notifications(RequestOptions r, _Account me) {
    final inbox = _notificationStore.putIfAbsent(me.id, () => []);
    final now = DateTime.now().toUtc().toIso8601String();
    int unread() => inbox.where((n) => n['readAt'] == null).length;
    if (r.method == 'DELETE') {
      final cleared = inbox.length;
      inbox.clear();
      return (200, okEnvelope({'clearedCount': cleared, 'unreadCount': 0}));
    }
    if (r.path == '/notifications/unread-count') return (200, okEnvelope({'unreadCount': unread()}));
    if (r.path == '/notifications/read-all') {
      final updated = unread();
      for (final n in inbox) {
        n['readAt'] ??= now;
      }
      return (200, okEnvelope({'updatedCount': updated, 'unreadCount': 0}));
    }
    if (r.method == 'POST' && r.path.endsWith('/read')) {
      final id = r.path.substring('/notifications/'.length, r.path.length - '/read'.length);
      final n = inbox.where((n) => n['id'] == id).firstOrNull;
      if (n == null) return (404, errorEnvelope('NOTIFICATION_NOT_FOUND'));
      n['readAt'] ??= now;
      return (200, okEnvelope(n));
    }
    final unreadOnly = r.queryParameters['filter'] == 'unread';
    return (200, okEnvelope(_page([for (final n in inbox) if (!unreadOnly || n['readAt'] == null) n], r)));
  }

  /// One page of [all] for the request's `page` / `size` (the API's `Pagination` shape).
  Map<String, dynamic> _page(List<Map<String, dynamic>> all, RequestOptions r) {
    final page = r.queryParameters['page'] as int? ?? 0;
    final size = r.queryParameters['size'] as int? ?? 20;
    return {
      'items': all.skip(page * size).take(size).toList(),
      'page': page,
      'size': size,
      'totalElements': all.length,
      'totalPages': (all.length / size).ceil(),
      'hasNext': (page + 1) * size < all.length,
    };
  }

  /// The dev account's sample orders and notifications (same as the app showed before slice E).
  void _seedOrdersAndNotifications(String accountId) {
    String ago(Duration d) => DateTime.now().toUtc().subtract(d).toIso8601String();
    Map<String, dynamic> amount(double v) => {'amount': v.toStringAsFixed(2), 'currency': 'USD'};
    Map<String, dynamic> line(Product p, int quantity) =>
        {'productId': p.id, 'name': p.name, 'quantity': quantity, 'unitPrice': amount(p.price), 'lineTotal': amount(p.price * quantity)};
    const delivery = {'recipientName': 'Alex Morgan', 'email': 'alex@example.com', 'address': '12 Riverside Street, Phnom Penh'};
    Map<String, dynamic> order(String id, String reference, String status, List<Map<String, dynamic>> items, double subtotal, Duration created, Duration updated) => {
          'id': id,
          'reference': reference,
          'status': status,
          'items': items,
          'delivery': delivery,
          'deliveryMethod': 'standard',
          'estimatedDelivery': '2–4 business days',
          'paymentMethod': 'cash_on_delivery',
          'subtotal': amount(subtotal),
          'deliveryFee': amount(4),
          'total': amount(subtotal + 4),
          'createdAt': ago(created),
          'updatedAt': ago(updated),
        };
    _orderStore[accountId] = [
      order('d1984200-0000-4000-8000-000000000002', 'MC-19842', 'shipped', [line(mockProducts[1], 1)], 74, const Duration(days: 3), const Duration(days: 1)),
      order('d2048100-0000-4000-8000-000000000001', 'MC-20481', 'delivered', [line(mockProducts[0], 1), line(mockProducts[2], 2)], 205, const Duration(days: 14), const Duration(days: 11)),
    ];
    Map<String, dynamic> note(String id, String type, String title, String message, Duration created, {Duration? read}) =>
        {'id': id, 'type': type, 'title': title, 'message': message, 'readAt': read == null ? null : ago(read), 'createdAt': ago(created)};
    _notificationStore[accountId] = [
      note('a1111111-1111-4111-8111-111111111111', 'order', 'Your order is on the way', 'Order #MC-19842 has shipped and is moving toward Phnom Penh.', const Duration(hours: 2)),
      note('b2222222-2222-4222-8222-222222222222', 'offer', 'A little something for you', 'Enjoy free standard delivery on your next order.', const Duration(hours: 5)),
      note('c3333333-3333-4333-8333-333333333333', 'stock', 'Back in stock', 'Cloud Sneakers from your wishlist are available again.', const Duration(days: 1, hours: 2), read: const Duration(days: 1)),
      note('d4444444-4444-4444-8444-444444444444', 'order', 'Order delivered', 'Order #MC-20481 was delivered. We hope you enjoy it.', const Duration(days: 12, hours: 1), read: const Duration(days: 12)),
    ];
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
        'counts': {
          'orders': _orderStore[a.id]?.length ?? 0,
          'wishlistItems': _wishlists[a.id]?.length ?? 0,
          'cartItems': (_carts[a.id] ?? const <_CartLine>[]).fold<int>(0, (sum, l) => sum + l.quantity),
        },
        'createdAt': a.createdAt,
        'updatedAt': a.createdAt,
      };
}

/// A product as the API sends it: money as a decimal string, rating as a string, badges lowercase,
/// and the description only on product details.
Map<String, dynamic> productJson(Product p, {bool withDescription = false, bool saved = false}) => {
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
      'saved': saved,
    };
