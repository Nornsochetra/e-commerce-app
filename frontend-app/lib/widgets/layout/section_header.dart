import 'package:flutter/material.dart';

import '../../theme.dart';

/// Section title with an optional link on the right, e.g. "Trending now        See all".
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: AppSpacing.md),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(child: Semantics(header: true, child: Text(title, style: AppText.section))),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs)),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
