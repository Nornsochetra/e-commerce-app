/// Notification types in v1.
enum NotificationType { order, offer, stock }

/// An in-app notification.
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? readAt; // null = unread

  const AppNotification({required this.id, required this.type, required this.title, required this.message, required this.createdAt, this.readAt});

  bool get isRead => readAt != null;

  AppNotification markRead() =>
      AppNotification(id: id, type: type, title: title, message: message, createdAt: createdAt, readAt: readAt ?? DateTime.now());

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: NotificationType.values.byName(json['type'] as String),
        title: json['title'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        readAt: json['readAt'] == null ? null : DateTime.parse(json['readAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
      };
}
