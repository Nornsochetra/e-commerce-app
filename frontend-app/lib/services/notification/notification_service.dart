import '../../models/common/page_result.dart';
import '../../models/notification/app_notification.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';

/// The in-app inbox through the API (NTF-*). Failures throw ApiException.
class NotificationService {
  final ApiClient _api;
  NotificationService([ApiClient? api]) : _api = api ?? ApiClient.instance;

  /// Newest first.
  Future<PageResult<AppNotification>> getPage({int page = 0, int size = ApiConfig.pageSize}) async => PageResult.fromJson(
        await _api.get('/notifications', query: {'page': page, 'size': size, 'filter': 'all'}) as Map<String, dynamic>,
        AppNotification.fromJson,
      );

  Future<int> getUnreadCount() async => ((await _api.get('/notifications/unread-count') as Map<String, dynamic>)['unreadCount'] as num).toInt();

  /// Returns the notification as now stored (with its read time).
  Future<AppNotification> markRead(String id) async => AppNotification.fromJson(await _api.post('/notifications/$id/read') as Map<String, dynamic>);

  /// Returns the unread count afterwards.
  Future<int> markAllRead() async => ((await _api.post('/notifications/read-all') as Map<String, dynamic>)['unreadCount'] as num).toInt();

  /// Clears the inbox on the server. This can't be undone.
  Future<void> clearAll() => _api.delete('/notifications');
}
