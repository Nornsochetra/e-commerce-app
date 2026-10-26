import 'package:flutter/material.dart';

import '../../theme.dart';

/// Tappable white strip: green icon tile, text, and a chevron or a short link label.
/// Used for the Home order update and "2 already in your cart" on product details.
class LinkBanner extends StatelessWidget {
  final IconData icon;
  final Widget child;
  final VoidCallback onTap;
  final String? actionLabel; // shown instead of the chevron, e.g. "View cart"
  final String semanticLabel;

  const LinkBanner({super.key, required this.icon, required this.child, required this.onTap, required this.semanticLabel, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), side: const BorderSide(color: AppColors.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  child: Icon(icon, size: 20, color: AppColors.primaryDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: child),
                const SizedBox(width: AppSpacing.sm),
                if (actionLabel != null)
                  Text(actionLabel!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark))
                else
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
