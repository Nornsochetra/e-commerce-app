import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/product/product_filter.dart';
import '../../providers/product/product_provider.dart';
import '../../theme.dart';
import '../../widgets/buttons/circle_icon_button.dart';
import '../../widgets/cards/product_grid.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/inputs/category_chip.dart';
import '../../widgets/inputs/search_bar.dart';
import '../../widgets/layout/app_header.dart';
import 'widgets/filter_sheet.dart';

/// SCR-008/009/011/012 Categories: search, category chips, sort, and the filter bottom sheet.
/// Opened as `/categories[?category=<slug>][&focus=search][&filters=open]`.
/// The category lives in the route; search, sort and filters live in [ProductProvider]
/// so they are kept while the user visits other tabs.
class CategoriesScreen extends StatefulWidget {
  final String? category; // category slug from /categories?category=bags (null = all)
  final bool focusSearch; // /categories?focus=search (Home search bar)
  final bool openFilters; // /categories?filters=open (Home filter button)

  const CategoriesScreen({super.key, this.category, this.focusSearch = false, this.openFilters = false});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _searchFocus = FocusNode();
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: context.read<ProductProvider>().filter.query);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().showCategory(widget.category);
      _handleRouteRequests(widget.focusSearch, widget.openFilters);
    });
  }

  @override
  void didUpdateWidget(CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.category != oldWidget.category) {
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? context.read<ProductProvider>().showCategory(widget.category) : null);
    }
    final focus = widget.focusSearch && !oldWidget.focusSearch;
    final filters = widget.openFilters && !oldWidget.openFilters;
    if (focus || filters) WidgetsBinding.instance.addPostFrameCallback((_) => _handleRouteRequests(focus, filters));
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  void _handleRouteRequests(bool focus, bool filters) {
    if (!mounted) return;
    if (focus) _searchFocus.requestFocus();
    if (filters) _openFilters();
  }

  /// Changing category replaces the route, so links from Home always show the right category.
  void _pickCategory(String? slug) => context.go(slug == null ? '/categories' : '/categories?category=$slug');

  void _openFilters() => showFilterSheet(context, categorySlug: widget.category, onCategory: _pickCategory);

  void _onSearch(String value) {
    final products = context.read<ProductProvider>();
    products.updateFilter(products.filter.copyWith(query: value));
  }

  void _clearSearch() {
    _search.clear();
    _onSearch('');
    _searchFocus.requestFocus();
  }

  void _clearAll() {
    _search.clear();
    context.read<ProductProvider>().resetFilter();
    _pickCategory(null);
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final filter = products.filter;
    final category = products.categoryBySlug(widget.category);
    final shown = products.results;
    final total = products.resultsTotal;
    final query = filter.query.trim();

    final summary = [if (query.isNotEmpty) ' for “$query”', if (filter.inStockOnly) ' · in stock'].join();

    return Scaffold(
      appBar: AppHeader(
        title: category?.name ?? 'Categories',
        backFallback: '/home',
        trailing: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIconButton(icon: Icons.tune_rounded, tooltip: filter.hasOptions ? 'Filter and sort, options on' : 'Filter and sort', onPressed: _openFilters),
            if (filter.hasOptions)
              Positioned(
                top: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      // Loads the next page of results when the list is scrolled close to its end.
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) products.loadMoreResults();
          return false;
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            AppSearchBar(controller: _search, focusNode: _searchFocus, onChanged: _onSearch, onClear: _clearSearch),
            const SizedBox(height: AppSpacing.lg),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  CategoryChip(label: 'All', selected: category == null, onTap: () => _pickCategory(null)),
                  for (final c in products.categories) ...[
                    const SizedBox(width: AppSpacing.sm),
                    CategoryChip(label: c.name, iconAsset: categoryIconAsset(c.slug), selected: category?.id == c.id, onTap: () => _pickCategory(c.slug)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text.rich(
                      TextSpan(
                        style: AppText.meta,
                        children: [
                          TextSpan(
                            text: '$total',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text),
                          ),
                          TextSpan(text: ' ${total == 1 ? 'product' : 'products'}$summary'),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _SortMenu(
                  value: filter.sort,
                  onChanged: (s) => products.updateFilter(filter.copyWith(sort: s)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (products.resultsLoading && shown.isEmpty)
              const ProductGridSkeleton()
            else if (products.resultsError != null)
              EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Couldn’t load products',
                message: products.resultsError!,
                actionLabel: 'Try again',
                onAction: products.categories.isEmpty ? products.load : products.refreshResults,
              )
            else if (shown.isEmpty)
              EmptyState(
                icon: Icons.search_rounded,
                title: 'No products found',
                message: query.isNotEmpty ? 'Nothing matches “$query”. Check the spelling or try a broader term.' : 'No products match these filters.',
                actionLabel: 'Clear search & filters',
                onAction: _clearAll,
              )
            else ...[
              if (products.resultsLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ProductGrid(products: shown),
              if (products.resultsLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped sort dropdown ("Featured ▾").
class _SortMenu extends StatelessWidget {
  final ProductSort value;
  final ValueChanged<ProductSort> onChanged;
  const _SortMenu({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sort products',
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ProductSort>(
            value: value,
            onChanged: (s) => s == null ? null : onChanged(s),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            dropdownColor: AppColors.surface,
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
            items: [for (final s in ProductSort.values) DropdownMenuItem(value: s, child: Text(s.label))],
          ),
        ),
      ),
    );
  }
}
