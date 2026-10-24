import 'package:flutter/material.dart';

import '../../theme.dart';
import '../buttons/app_button.dart';

/// Friendly message for empty lists and "not found" pages, with a clear next action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool danger; // rose colours (e.g. empty wishlist)

  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final tint = danger ? const Color(0xFFFFF1F2) : AppColors.mintSoft;
    final ring = danger ? const Color(0xFFFECDD3) : AppColors.mint;
    final color = danger ? AppColors.error : AppColors.primaryDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 48, AppSpacing.md, AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle, border: Border.all(color: ring, width: 1, strokeAlign: BorderSide.strokeAlignInside)),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: AppText.section, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(message, style: AppText.bodyMuted, textAlign: TextAlign.center),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: actionLabel!, onPressed: onAction, expanded: false),
          ],
        ],
      ),
    );
  }
}
