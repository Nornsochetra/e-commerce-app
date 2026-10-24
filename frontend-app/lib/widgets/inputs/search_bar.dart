import 'package:flutter/material.dart';

import '../../theme.dart';

/// Pill search field. With [onTap] and [readOnly] it acts as a button that opens the search screen.
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final String hint;

  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.hint = 'Search products',
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: AppColors.line));
    final hasText = controller != null && controller!.text.isNotEmpty;
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: AppSpacing.shadowSoft, borderRadius: BorderRadius.all(Radius.circular(999))),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 14),
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
          suffixIcon: hasText && onClear != null
              ? IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded, size: 20), color: AppColors.textMuted, onPressed: onClear)
              : null,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }
}
