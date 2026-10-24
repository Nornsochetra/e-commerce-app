import 'package:flutter/material.dart';

import '../../theme.dart';

/// Floating bottom bar for a screen's main action (Add to cart, Checkout, Place order).
/// Use it as `Scaffold(bottomNavigationBar: ActionDock(children: [...]))` on screens without the tab bar.
class ActionDock extends StatelessWidget {
  final List<Widget> children;
  const ActionDock({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line),
            boxShadow: AppSpacing.shadowFloat,
          ),
          child: Row(children: children),
        ),
      ),
    );
  }
}
