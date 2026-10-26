import '../api/api_client.dart';
import '../api/api_exception.dart';

/// Checks that the Spring API is running (GET /health · HLT-0601).
class HealthService {
  final ApiClient _api;
  HealthService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  /// True when the server answers and reports it is up.
  Future<bool> isAvailable() async {
    try {
      final data = await _api.get('/health', auth: false) as Map<String, dynamic>;
      return data['status'] == 'UP';
    } on ApiException {
      return false;
    }
  }
}
