import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/mock_data.dart';
import '../../models/notification/app_notification.dart';

/// Loads and saves notifications. Later: GET /notifications, POST /notifications/{id}/read, …
class NotificationService {
  static const _key = 'notifications';

  Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(mockDelay);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return mockNotifications();
    return (jsonDecode(raw) as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveNotifications(List<AppNotification> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  /// Adds a new unread notification at the top (used when an order is placed).
  Future<void> addNotification({required NotificationType type, required String title, required String message}) async {
    final items = await getNotifications();
    final now = DateTime.now();
    items.insert(0, AppNotification(id: 'n-${now.microsecondsSinceEpoch}', type: type, title: title, message: message, createdAt: now));
    await saveNotifications(items);
  }
}
