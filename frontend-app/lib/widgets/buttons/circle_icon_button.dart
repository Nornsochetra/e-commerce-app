import 'package:flutter/material.dart';

import '../../theme.dart';

/// Look of a [CircleIconButton].
enum CircleButtonStyle { plain, solid, onImage }

/// Round icon button used for back, favourite, filter, bell and similar actions.
/// The tap area is always at least 44×44, even for the small size.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip; // read by screen readers
  final double size;
  final CircleButtonStyle style;
  final Color? iconColor;
  final int badgeCount;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 44,
    this.style = CircleButtonStyle.plain,
    this.iconColor,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final background = switch (style) {
      CircleButtonStyle.plain => AppColors.surface,
      CircleButtonStyle.solid => AppColors.primaryDark,
      CircleButtonStyle.onImage => Colors.white.withValues(alpha: 0.92),
    };
    final foreground = iconColor ?? (style == CircleButtonStyle.solid ? Colors.white : AppColors.text);
    final button = DecoratedBox(
      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: AppSpacing.shadowSoft),
      child: Material(
        color: background,
        shape: CircleBorder(side: style == CircleButtonStyle.plain ? const BorderSide(color: AppColors.line) : BorderSide.none),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(dimension: size, child: Icon(icon, size: size * 0.46, color: onPressed == null ? foreground.withValues(alpha: 0.4) : foreground)),
        ),
      ),
    );

    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: size < 44 ? 44 : size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            button,
            if (badgeCount > 0)
              Positioned(
                top: size < 44 ? 0 : -3,
                right: size < 44 ? 0 : -3,
                child: _Badge(count: badgeCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.background, width: 2)),
      alignment: Alignment.center,
      child: Text(count > 9 ? '9+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, height: 1)),
    );
  }
}
