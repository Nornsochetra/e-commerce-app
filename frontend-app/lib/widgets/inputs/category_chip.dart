import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme.dart';

/// Icon file for a category. Category icons are an app design choice (not sent by the API).
String? categoryIconAsset(String slug) => switch (slug) {
      'accessories' || 'footwear' || 'bags' || 'electronics' => 'assets/icons/category_$slug.svg',
      _ => null,
    };

/// Pill chip used for categories and filters. Selected chips are green.
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? iconAsset; // optional SVG from assets/icons
  final int? count; // small number bubble, e.g. "Unread 2"

  const CategoryChip({super.key, required this.label, required this.onTap, this.selected = false, this.iconAsset, this.count});

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.text;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primaryDark : AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconAsset != null) ...[
                  SvgPicture.asset(iconAsset!, width: 18, height: 18, colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn)),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: foreground)),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: selected ? Colors.white24 : AppColors.mint, borderRadius: BorderRadius.circular(10)),
                    child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.primaryDeep)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
