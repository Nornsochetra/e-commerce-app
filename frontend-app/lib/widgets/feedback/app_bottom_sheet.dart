import 'package:flutter/material.dart';

import '../../theme.dart';

/// Opens a rounded bottom sheet with a title. The sheet moves up with the keyboard.
/// It opens above the floating tab bar (root navigator), so its buttons are never hidden.
/// Returns whatever the sheet passes to `Navigator.pop(context, value)`.
/// Set [enableDrag] to false for forms, so unsaved edits can't be swiped away.
Future<T?> showAppBottomSheet<T>(BuildContext context, {required String title, required Widget child, bool enableDrag = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    enableDrag: enableDrag,
    showDragHandle: enableDrag,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        enableDrag ? 0 : AppSpacing.xxl, // room the drag handle would take
        AppSpacing.page,
        AppSpacing.xxl + MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.section),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    ),
  );
}
