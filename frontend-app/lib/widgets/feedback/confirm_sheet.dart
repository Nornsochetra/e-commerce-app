import 'package:flutter/material.dart';

import '../../theme.dart';
import '../buttons/app_button.dart';
import 'app_bottom_sheet.dart';

/// Asks "Are you sure?" in a bottom sheet with Cancel and a confirm button.
/// Returns true only when the user taps [confirmLabel]. Use [danger] for destructive actions (red button).
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool danger = false,
}) async {
  final confirmed = await showAppBottomSheet<bool>(
    context,
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: AppText.bodyMuted),
        const SizedBox(height: AppSpacing.xxl),
        Builder(
          builder: (sheetContext) => Row(
            children: [
              Expanded(child: AppButton(label: cancelLabel, variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(sheetContext, false))),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: confirmLabel,
                  variant: danger ? AppButtonVariant.dangerSolid : AppButtonVariant.primary,
                  onPressed: () => Navigator.pop(sheetContext, true),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
