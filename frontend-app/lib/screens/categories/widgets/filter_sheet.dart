import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product/product_filter.dart';
import '../../../providers/product/product_provider.dart';
import '../../../theme.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feedback/app_bottom_sheet.dart';
import '../../../widgets/inputs/category_chip.dart';

/// SCR-012 "Filter & sort" bottom sheet. Changes apply straight away; the button shows how many
/// products match. [onCategory] gets the picked slug (null = all categories).
Future<void> showFilterSheet(BuildContext context, {required String? categorySlug, required ValueChanged<String?> onCategory}) {
  return showAppBottomSheet<void>(
    context,
    title: 'Filter & sort',
    child: _FilterSheet(categorySlug: categorySlug, onCategory: onCategory),
  );
}

class _FilterSheet extends StatefulWidget {
  final String? categorySlug;
  final ValueChanged<String?> onCategory;
  const _FilterSheet({required this.categorySlug, required this.onCategory});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _slug = widget.categorySlug;

  void _pickCategory(String? slug) {
    setState(() => _slug = slug);
    widget.onCategory(slug);
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final filter = products.filter;
    final count = products.search(categoryId: products.categoryBySlug(_slug)?.id).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Category'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            CategoryChip(label: 'All', selected: _slug == null, onTap: () => _pickCategory(null)),
            for (final c in products.categories) CategoryChip(label: c.name, selected: _slug == c.slug, onTap: () => _pickCategory(c.slug)),
          ],
        ),
        const _Label('Sort by'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in ProductSort.values)
              CategoryChip(label: s.label, selected: filter.sort == s, onTap: () => products.updateFilter(filter.copyWith(sort: s))),
          ],
        ),
        const _Label('Availability'),
        Material(
          color: filter.inStockOnly ? AppColors.mintSoft : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(color: filter.inStockOnly ? AppColors.primary : AppColors.line, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: SwitchListTile(
            value: filter.inStockOnly,
            onChanged: (v) => products.updateFilter(filter.copyWith(inStockOnly: v)),
            title: const Text('In stock only', style: AppText.head),
            subtitle: const Text('Hide sold-out products', style: AppText.meta),
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.success,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Reset',
                variant: AppButtonVariant.outline,
                onPressed: () {
                  products.updateFilter(filter.copyWith(sort: ProductSort.featured, inStockOnly: false));
                  _pickCategory(null);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: AppButton(label: 'Show $count ${count == 1 ? 'product' : 'products'}', onPressed: () => Navigator.pop(context))),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: 10),
        child: Text(text.toUpperCase(), style: AppText.meta.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.7)),
      );
}
