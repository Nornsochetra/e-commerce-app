import 'package:flutter/material.dart';

import '../../theme.dart';

/// Short message at the bottom of the screen, with an optional action such as "Undo" or "View cart".
void showAppToast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: Duration(milliseconds: actionLabel == null ? 2600 : 5000),
      content: Row(children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ),
  );
}
