import 'package:flutter/foundation.dart';

import '../../models/notification/app_notification.dart';
import '../../services/api/api_exception.dart';
import '../../services/notification/notification_service.dart';
import '../auth/follows_sign_in.dart';

/// The in-app inbox and the unread badge, from the server. Follows sign-in (guests have none).
/// Home and Profile only need the badge ([loadUnreadCount]); the list loads when the Notifications
/// screen opens ([ensureLoaded]), one page at a time ([loadMore]).
class NotificationProvider extends ChangeNotifier with FollowsSignIn {
  final _service = NotificationService();

  List<AppNotification> items = []; // newest first
  int unreadCount = 0; // from the server, so it counts pages not loaded yet too
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasNext = false;
  String? error;
  int _page = 0;

  @override
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _service.getPage();
      items = page.items;
      hasNext = page.hasNext;
      _page = page.page;
      unreadCount = await _service.getUnreadCount();
    } on ApiException catch (e) {
      error = e.userMessage;
    }
    isLoading = false;
    notifyListeners();
  }

  bool _countRequested = false;

  /// Reads the unread count the first time a screen with the bell is shown.
  void ensureUnreadCount() {
    if (!signedIn || _countRequested) return;
    _countRequested = true;
    loadUnreadCount();
  }

  /// Reads only the unread count (the bell badge), without the list.
  Future<void> loadUnreadCount() async {
    if (!signedIn) return;
    try {
      unreadCount = await _service.getUnreadCount();
      notifyListeners();
    } on ApiException {
      // Keep the last known count.
    }
  }

  /// Appends the next page (called while scrolling).
  Future<void> loadMore() async {
    if (!hasNext || isLoading || isLoadingMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _service.getPage(page: _page + 1);
      items = [...items, ...page.items];
      hasNext = page.hasNext;
      _page = page.page;
    } on ApiException {
      // Keep what is shown; scrolling again retries.
    }
    isLoadingMore = false;
    notifyListeners();
  }

  /// Guests have no notifications: hides them (nothing on the server changes).
  @override
  void unload() {
    items = [];
    unreadCount = 0;
    hasNext = false;
    _countRequested = false;
    notifyListeners();
  }

  /// Marks one as read straight away; puts it back if the server refuses.
  /// Returns a user-facing error, or null when it worked.
  Future<String?> markRead(String id) async {
    final index = items.indexWhere((n) => n.id == id);
    if (index == -1 || items[index].isRead) return null;
    final before = items[index];
    items = [...items]..[index] = before.markRead();
    unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
    notifyListeners();
    try {
      final saved = await _service.markRead(id);
      items = [for (final n in items) n.id == id ? saved : n];
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      items = [for (final n in items) n.id == id ? before : n];
      unreadCount++;
      notifyListeners();
      return e.userMessage;
    }
  }

  /// Returns a user-facing error, or null when it worked.
  Future<String?> markAllRead() async {
    try {
      unreadCount = await _service.markAllRead();
      items = [for (final n in items) n.markRead()];
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.userMessage;
    }
  }

  /// Clears the whole inbox on the server (no undo). Returns a user-facing error, or null when it worked.
  Future<String?> clearAll() async {
    try {
      await _service.clearAll();
      items = [];
      unreadCount = 0;
      hasNext = false;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.userMessage;
    }
  }
}
