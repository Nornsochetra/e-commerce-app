import 'package:flutter/material.dart';

import '../../../models/cart/cart_item.dart';
import '../../../theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/buttons/circle_icon_button.dart';
import '../../../widgets/cards/product_image.dart';
import '../../../widgets/inputs/quantity_stepper.dart';

/// One cart line: photo, name, unit price, remove, "Save for later" (or the stock limit), quantity and line total.
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onOpen;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;
  final VoidCallback onSaveForLater;

  const CartItemTile({super.key, required this.item, required this.onOpen, required this.onQuantity, required this.onRemove, required this.onSaveForLater});

  @override
  Widget build(BuildContext context) {
    final atMax = item.quantity >= item.availableQuantity;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
            label: 'View ${item.name}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onOpen,
              child: SizedBox(
                width: 84,
                height: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: ProductImage(url: item.imageUrl),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
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
                          GestureDetector(
                            onTap: onOpen,
                            child: Text(item.name, style: AppText.head, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(height: 2),
                          Text('${item.categoryName} · ${formatMoney(item.unitPrice)} each', style: AppText.meta),
                        ],
                      ),
                    ),
                    CircleIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Remove ${item.name} from cart', size: 36, onPressed: onRemove),
                  ],
                ),
                if (atMax)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Only ${item.availableQuantity} available',
                      style: AppText.meta.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: onSaveForLater,
                    icon: const Icon(Icons.favorite_border_rounded, size: 14),
                    label: const Text('Save for later'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    QuantityStepper(value: item.quantity, max: item.availableQuantity, productName: item.name, onChanged: onQuantity),
                    const Spacer(),
                    Text(formatMoney(item.lineTotal), style: AppText.price),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
