import 'package:flutter/material.dart';

import '../../theme.dart';

/// Colour of a [StatusBadge].
enum BadgeTone { success, warning, error, info, neutral }

/// Small pill label, e.g. "In stock", "Shipped", "Soon".
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;

  const StatusBadge({super.key, required this.label, this.tone = BadgeTone.neutral});

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (tone) {
      BadgeTone.success => (AppColors.successBg, AppColors.primaryDeep),
      BadgeTone.warning => (AppColors.warningBg, const Color(0xFF92400E)),
      BadgeTone.error => (AppColors.errorBg, const Color(0xFF991B1B)),
      BadgeTone.info => (AppColors.infoBg, const Color(0xFF1E40AF)),
      BadgeTone.neutral => (AppColors.field, const Color(0xFF475569)),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      // widthFactor keeps the pill as wide as its text, even inside a Wrap or Column.
      child: Center(widthFactor: 1, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: foreground))),
    );
  }
}
