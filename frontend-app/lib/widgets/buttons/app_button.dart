import 'package:flutter/material.dart';

import '../../theme.dart';

/// Button styles used across the app.
enum AppButtonVariant { primary, secondary, outline, danger, text }

/// Pill-shaped button. Shows a spinner and ignores taps while [isLoading] is true.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expanded; // full width
  final bool small; // 40px tall instead of 52px

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = small ? 40.0 : AppSpacing.controlHeight;
    final textStyle = AppText.button.copyWith(fontSize: small ? 13 : 15);
    final padding = EdgeInsets.symmetric(horizontal: small ? AppSpacing.lg : AppSpacing.xxl);
    final onTap = isLoading ? null : onPressed;

    final (Color background, Color foreground, BorderSide side) = switch (variant) {
      AppButtonVariant.primary => (AppColors.primaryDark, Colors.white, BorderSide.none),
      AppButtonVariant.secondary => (AppColors.mint, AppColors.primaryDeep, BorderSide.none),
      AppButtonVariant.outline => (AppColors.surface, AppColors.text, const BorderSide(color: AppColors.line, width: 1.5)),
      AppButtonVariant.danger => (AppColors.errorBg, const Color(0xFFB91C1C), BorderSide.none),
      AppButtonVariant.text => (Colors.transparent, AppColors.textMuted, BorderSide.none),
    };

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground))
        else if (icon != null)
          Icon(icon, size: 18),
        if (isLoading || icon != null) const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final button = TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: variant == AppButtonVariant.text ? 0 : 0.5),
        disabledForegroundColor: isLoading ? foreground : foreground.withValues(alpha: 0.6),
        minimumSize: Size(0, height),
        padding: padding,
        shape: StadiumBorder(side: side),
        textStyle: textStyle,
      ),
      child: child,
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
