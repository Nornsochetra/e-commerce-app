import 'package:flutter/material.dart';

import '../../models/product/product.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../buttons/circle_icon_button.dart';
import 'product_image.dart';

/// Horizontal card (photo on the left) used by Wishlist and Home "New arrivals".
class ProductListCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;

  const ProductListCard({super.key, required this.product, required this.isFavorite, required this.onTap, required this.onFavorite, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final subtitle = p.cardBadge == null ? p.categoryName : '${p.categoryName} · ${formatLabel(p.cardBadge!)}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.line),
        boxShadow: AppSpacing.shadowSoft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: 'View ${p.name}',
            child: GestureDetector(
              onTap: onTap,
              child: SizedBox(
                width: 96,
                height: 112,
                child: ClipRRect(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), child: ProductImage(url: p.imageUrl)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(subtitle, style: AppText.meta, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            GestureDetector(onTap: onTap, child: Text(p.name, style: AppText.head, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                              const SizedBox(width: 2),
                              Text(p.rating?.toStringAsFixed(1) ?? '–', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ]),
                          ],
                        ),
                      ),
                      CircleIconButton(
                        icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        iconColor: isFavorite ? AppColors.error : AppColors.text,
                        tooltip: isFavorite ? 'Remove ${p.name} from wishlist' : 'Save ${p.name} to wishlist',
                        size: 36,
                        onPressed: onFavorite,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(child: Text(formatMoney(p.price), style: AppText.price)),
                      CircleIconButton(
                        icon: Icons.add_shopping_cart_rounded,
                        tooltip: p.inStock ? 'Add ${p.name} to cart' : '${p.name} is sold out',
                        size: 36,
                        style: CircleButtonStyle.solid,
                        onPressed: p.inStock ? onAdd : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
