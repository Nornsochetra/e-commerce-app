import 'package:flutter/material.dart';

import '../../theme.dart';
import '../buttons/app_button.dart';

/// Asks "Are you sure?" in a centered popup with Cancel and a confirm button.
/// Returns true only when the user taps [confirmLabel]; tapping outside or Back counts as Cancel.
/// Use [danger] for destructive actions (red button).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool danger = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      titlePadding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
      contentPadding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, 0),
      actionsPadding: const EdgeInsets.all(AppSpacing.xxl),
      title: Text(title, style: AppText.section),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Text(message, style: AppText.bodyMuted),
      ),
      actions: [
        Row(
          children: [
            Expanded(child: AppButton(label: cancelLabel, variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(dialogContext, false))),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: confirmLabel,
                variant: danger ? AppButtonVariant.dangerSolid : AppButtonVariant.primary,
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
