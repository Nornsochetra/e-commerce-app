import 'package:flutter/material.dart';

import '../../theme.dart';

/// Labelled text field with inline error and an optional show/hide toggle for passwords.
class AppTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool optional; // adds "(optional)" after the label
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.optional = false,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(text: widget.label, style: AppText.label, children: [
          if (widget.optional) const TextSpan(text: ' (optional)', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textFaint)),
        ])),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: const TextStyle(fontSize: 15, color: AppColors.text),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            helperText: widget.helperText,
            helperMaxLines: 2,
            counterText: '',
            fillColor: widget.errorText != null ? const Color(0xFFFFF7F7) : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
