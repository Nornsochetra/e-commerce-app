import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/providers/notification/notification_provider.dart';
import 'package:frontend_app/services/api/api_client.dart';

import '../fake_api.dart';

void main() {
  late FakeBackend backend;
  late NotificationProvider inbox;

  Future<NotificationProvider> reloaded() async {
    final fresh = NotificationProvider();
    await fresh.load();
    return fresh;
  }

  setUp(() async {
    backend = FakeBackend();
    ApiClient.instance = backend.client;
    await backend.signIn();
    inbox = NotificationProvider();
    await inbox.load();
  });

  test('loads the inbox and the unread count from the server', () {
    expect(inbox.items, hasLength(4));
    expect(inbox.items.first.title, 'Your order is on the way'); // newest first
    expect(inbox.unreadCount, 2);
  });

  test('mark one and mark all as read are saved on the server', () async {
    expect(await inbox.markRead(inbox.items.first.id), isNull);
    expect(inbox.unreadCount, 1);
    expect((await reloaded()).unreadCount, 1);

    expect(await inbox.markAllRead(), isNull);
    expect(inbox.unreadCount, 0);
    expect(inbox.items.every((n) => n.isRead), isTrue);
    expect((await reloaded()).unreadCount, 0);
  });

  test('clear all empties the inbox on the server', () async {
    expect(await inbox.clearAll(), isNull);
    expect(inbox.items, isEmpty);
    expect(inbox.unreadCount, 0);
    expect((await reloaded()).items, isEmpty);
  });

  test('when marking as read fails, the notification stays unread', () async {
    backend.offline = true;
    final first = inbox.items.first;
    expect(await inbox.markRead(first.id), contains('Can’t reach APM'));
    expect(inbox.items.first.isRead, isFalse);
    expect(inbox.unreadCount, 2);
  });
}
