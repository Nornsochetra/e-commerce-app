/// Where the Spring API lives. Every path in docs/api.md is relative to this.
///
/// Set it when running the app:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8081/api/v1
///
/// The default works for the iOS simulator and web on the same computer as the backend.
/// The Android emulator reaches the computer at 10.0.2.2 instead of localhost.
class ApiConfig {
  static const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8081/api/v1');

  /// One page of any list (products, wishlist, orders, notifications). Screens load the next page
  /// while scrolling, so no list is ever loaded all at once (docs/api.md, API conventions §7).
  static const pageSize = 20;

  /// Products in each Home section ("Trending now", "New arrivals").
  static const homeSectionSize = 4;

  /// Products read for "You may also like" (2 are shown; one extra in case it is the product itself).
  static const relatedSize = 3;

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);
}
