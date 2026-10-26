/// Where the Spring API lives. Every path in docs/api-specification.md is relative to this.
///
/// Set it when running the app:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8081/api/v1
///
/// The default works for the iOS simulator and web on the same computer as the backend.
/// The Android emulator reaches the computer at 10.0.2.2 instead of localhost.
class ApiConfig {
  static const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8081/api/v1');

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);
}
