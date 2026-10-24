import 'package:flutter/material.dart';

import '../../theme.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.label, this.icon, this.activeIcon);
}

const _items = [
  _NavItem('Home', Icons.home_outlined, Icons.home_rounded),
  _NavItem('Categories', Icons.grid_view_outlined, Icons.grid_view_rounded),
  _NavItem('Wishlist', Icons.favorite_border_rounded, Icons.favorite_rounded),
  _NavItem('Cart', Icons.shopping_bag_outlined, Icons.shopping_bag_rounded),
  _NavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

/// Floating pill tab bar. The selected tab grows into a green pill with its label.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap, this.cartCount = 0});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.line),
            boxShadow: AppSpacing.shadowFloat,
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(flex: i == currentIndex ? 12 : 5, child: _NavButton(item: _items[i], selected: i == currentIndex, badge: i == 3 ? cartCount : 0, onTap: () => onTap(i))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final int badge;
  final VoidCallback onTap;
  const _NavButton({required this.item, required this.selected, required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      label: badge > 0 ? '${item.label}, $badge items' : item.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primaryDark : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(selected ? item.activeIcon : item.icon, size: 22, color: color),
                    if (badge > 0)
                      Positioned(
                        top: -6,
                        right: -10,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: selected ? AppColors.primaryDark : Colors.white, width: 2),
                          ),
                          child: Text(badge > 99 ? '99+' : '$badge',
                              style: TextStyle(fontSize: 10, height: 1, fontWeight: FontWeight.w800, color: selected ? AppColors.primaryDeep : Colors.white)),
                        ),
                      ),
                  ],
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(child: Text(item.label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
