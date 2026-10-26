import 'package:flutter/foundation.dart';

import '../auth/follows_sign_in.dart';
import '../../models/notification/app_notification.dart';
import '../../services/notification/notification_service.dart';

/// In-app notifications and the unread badge on the bell.
class NotificationProvider extends ChangeNotifier with FollowsSignIn {
  final _service = NotificationService();

  List<AppNotification> items = [];
  bool isLoading = false;

  int get unreadCount => items.where((n) => !n.isRead).length;

  @override
  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    items = await _service.getNotifications();
    isLoading = false;
    notifyListeners();
  }

  /// Guests have no notifications: hides them (nothing is deleted).
  @override
  void unload() {
    items = [];
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    items = items.map((n) => n.id == id ? n.markRead() : n).toList();
    await _save();
  }

  Future<void> markAllRead() async {
    items = items.map((n) => n.markRead()).toList();
    await _save();
  }

  /// Clears the inbox and returns the old list, so the screen can offer "Undo".
  Future<List<AppNotification>> clearAll() async {
    final previous = items;
    items = [];
    await _save();
    return previous;
  }

  Future<void> restore(List<AppNotification> previous) async {
    items = previous;
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    await _service.saveNotifications(items);
  }
}
