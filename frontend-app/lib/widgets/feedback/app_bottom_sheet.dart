import 'package:flutter/material.dart';

import '../../theme.dart';

/// Opens a rounded bottom sheet with a title. The sheet moves up with the keyboard.
/// Returns whatever the sheet passes to `Navigator.pop(context, value)`.
Future<T?> showAppBottomSheet<T>(BuildContext context, {required String title, required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
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
