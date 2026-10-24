import 'package:flutter/material.dart';

import '../../models/product/product.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../buttons/circle_icon_button.dart';
import 'product_image.dart';

/// Grid card: tall photo with a heart and an "Add" button on it, then name, category, price and rating.
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;

  const ProductCard({super.key, required this.product, required this.isFavorite, required this.onTap, required this.onFavorite, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: 'View ${p.name}',
                  child: GestureDetector(
                    onTap: onTap,
                    child: ClipRRect(borderRadius: BorderRadius.circular(AppSpacing.radiusLg), child: ProductImage(url: p.imageUrl)),
                  ),
                ),
              ),
              if (p.badges.isNotEmpty) Positioned(left: 10, top: 10, child: _Tag(formatLabel(p.badges.first))),
              Positioned(
                right: 4,
                top: 4,
                child: CircleIconButton(
                  icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: isFavorite ? AppColors.error : AppColors.text,
                  tooltip: isFavorite ? 'Remove ${p.name} from wishlist' : 'Save ${p.name} to wishlist',
                  size: 36,
                  style: CircleButtonStyle.onImage,
                  onPressed: onFavorite,
                ),
              ),
              Positioned(left: 8, bottom: 8, child: p.inStock ? _AddButton(name: p.name, onTap: onAdd) : const _SoldOut()),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        GestureDetector(
          onTap: onTap,
          child: Text(p.name, style: AppText.head, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Text(p.categoryName, style: AppText.meta),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(child: Text(formatMoney(p.price), style: AppText.price)),
            const Icon(Icons.star_rounded, size: 15, color: AppColors.star),
            const SizedBox(width: 2),
            Text(p.rating?.toStringAsFixed(1) ?? '–', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) => Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(12), boxShadow: AppSpacing.shadowSoft),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text)),
      );
}

class _AddButton extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _AddButton({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Add $name to cart',
        excludeSemantics: true,
        child: Material(
          color: AppColors.primaryDark,
          shape: const StadiumBorder(),
          elevation: 3,
          shadowColor: AppColors.primaryDark.withValues(alpha: 0.5),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(10, 8, 14, 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, size: 18, color: Colors.white),
                SizedBox(width: 4),
                Text('Add', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      );
}

class _SoldOut extends StatelessWidget {
  const _SoldOut();

  @override
  Widget build(BuildContext context) => Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xC70F172A), borderRadius: BorderRadius.circular(15)),
        child: const Text('Sold out', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}
