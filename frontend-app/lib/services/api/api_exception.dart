/// A failed API call. [code] is the backend's stable error code (docs/api-convention.md §2),
/// or [ApiException.network] / [ApiException.timeout] when the server couldn't be reached.
///
/// Screens show [userMessage]. The server's own `message` is for developers only and is kept in
/// [debugMessage] for logs.
class ApiException implements Exception {
  static const network = 'NETWORK_ERROR';
  static const timeout = 'TIMEOUT';

  final String code;
  final int? statusCode;
  final String? debugMessage;
  final List<FieldError> fieldErrors;
  final String? requestId;

  const ApiException(this.code, {this.statusCode, this.debugMessage, this.fieldErrors = const [], this.requestId});

  /// Builds the exception from a failed `ApiResponse` envelope.
  factory ApiException.fromEnvelope(Map<String, dynamic> body, {int? statusCode}) {
    final error = body['error'] as Map<String, dynamic>?;
    final status = body['status'] as Map<String, dynamic>?;
    final details = (error?['details'] as List?) ?? const [];
    return ApiException(
      (error?['code'] ?? status?['code'] ?? 'INTERNAL_ERROR') as String,
      statusCode: statusCode,
      debugMessage: (error?['message'] ?? status?['message']) as String?,
      fieldErrors: [
        for (final d in details.whereType<Map<String, dynamic>>()) FieldError(field: d['field'] as String? ?? '', message: d['message'] as String? ?? ''),
      ],
      requestId: (body['common'] as Map<String, dynamic>?)?['requestId'] as String?,
    );
  }

  /// True when the request never got an answer (offline, server down, timeout).
  bool get isConnectionProblem => code == network || code == timeout;

  /// Text that is safe to show to the user.
  String get userMessage => _messages[code] ?? (statusCode != null && statusCode! >= 500 ? _messages['INTERNAL_ERROR']! : 'Something went wrong. Please try again.');

  @override
  String toString() => 'ApiException($code, status: $statusCode, requestId: $requestId, $debugMessage)';
}

/// One rejected field from a `VALIDATION_ERROR` response.
class FieldError {
  final String field;
  final String message;
  const FieldError({required this.field, required this.message});
}

/// User-facing text for every error code the API can return (docs/api-convention.md §2.1–2.2).
const _messages = {
  ApiException.network: 'Can’t reach Mercato. Check your connection and try again.',
  ApiException.timeout: 'Mercato is taking too long to answer. Please try again.',
  // Universal
  'INVALID_REQUEST': 'Something in that request wasn’t right. Please try again.',
  'VALIDATION_ERROR': 'Some details aren’t valid. Check them and try again.',
  'UNAUTHORIZED': 'Please sign in to continue.',
  'INVALID_TOKEN': 'Your session has ended. Please sign in again.',
  'FORBIDDEN': 'You don’t have access to that.',
  'NOT_FOUND': 'We couldn’t find that.',
  'DUPLICATE': 'That already exists.',
  'CONFLICT': 'That changed in the meantime. Please refresh and try again.',
  'INTERNAL_ERROR': 'Something went wrong on our side. Please try again in a moment.',
  // Auth and profile
  'INVALID_CREDENTIALS': 'That email and password don’t match.',
  'ACCOUNT_DISABLED': 'This account has been disabled. Contact support for help.',
  'EMAIL_ALREADY_REGISTERED': 'An account with this email already exists.',
  'INVALID_REFRESH_TOKEN': 'Your session has ended. Please sign in again.',
  'USER_NOT_FOUND': 'We couldn’t find your account. Please sign in again.',
  // Catalog
  'PRODUCT_NOT_FOUND': 'This product is no longer available.',
  'CATEGORY_NOT_FOUND': 'This category is no longer available.',
  // Cart and wishlist
  'CART_NOT_FOUND': 'We couldn’t load your cart. Please try again.',
  'CART_ITEM_NOT_FOUND': 'That item is no longer in your cart.',
  'PRODUCT_OUT_OF_STOCK': 'This product is out of stock.',
  'INSUFFICIENT_STOCK': 'There isn’t enough stock for that quantity.',
  'WISHLIST_ITEM_NOT_FOUND': 'That product is no longer in your wishlist.',
  // Orders and notifications
  'ORDER_NOT_FOUND': 'We couldn’t find that order.',
  'CART_EMPTY': 'Your cart is empty.',
  'CHECKOUT_INVALID': 'Some checkout details aren’t valid. Check them and try again.',
  'NOTIFICATION_NOT_FOUND': 'That notification is no longer available.',
};
