import 'package:flutter/material.dart';

import '../../theme.dart';

/// White rounded card with a hairline border, or a mint [tint] card without one.
class AppCard extends StatelessWidget {
  final Widget child;
  final bool tint;
  final EdgeInsetsGeometry padding;

  const AppCard({super.key, required this.child, this.tint = false, this.padding = const EdgeInsets.all(AppSpacing.lg)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tint ? AppColors.mintSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: tint ? null : Border.all(color: AppColors.line),
        boxShadow: tint ? null : AppSpacing.shadowSoft,
      ),
      child: child,
    );
  }
}
