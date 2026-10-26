import 'package:flutter/material.dart';

import '../../../models/notification/app_notification.dart';
import '../../../theme.dart';
import '../../../utils/formatters.dart';

/// One notification row: type icon, title with an unread dot, message, "2 hours ago · Order",
/// and "Mark as read" while unread. Unread rows have a mint background.
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onOpen;
  final VoidCallback onMarkRead;

  const NotificationTile({super.key, required this.notification, required this.onOpen, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final unread = !n.isRead;
    final (IconData icon, Color tint, Color color, String type) = switch (n.type) {
      NotificationType.order => (Icons.inventory_2_outlined, AppColors.infoBg, AppColors.info, 'Order'),
      NotificationType.offer => (Icons.local_offer_outlined, AppColors.warningBg, AppColors.warning, 'Offer'),
      NotificationType.stock => (Icons.notifications_none_rounded, AppColors.mintSoft, AppColors.primaryDark, 'Back in stock'),
    };

    return Container(
      color: unread ? AppColors.mintSoft : null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: unread && n.type == NotificationType.stock ? AppColors.surface : tint, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  button: true,
                  label: '${n.title}${unread ? ', unread' : ''}. ${n.message}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onOpen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(n.title, style: const TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w700, color: AppColors.text))),
                            if (unread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6, left: AppSpacing.sm),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(n.message, style: AppText.bodyMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text('${timeAgo(n.createdAt)} · $type', style: AppText.meta)),
                    if (unread)
                      TextButton(
                        onPressed: onMarkRead,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Mark as read'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
