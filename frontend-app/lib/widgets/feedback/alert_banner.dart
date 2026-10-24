import 'package:flutter/material.dart';

import '../../theme.dart';

/// Colour of an [AlertBanner].
enum AlertTone { success, error, info, warning }

/// Inline message box, e.g. "That email and password don't match." or "Signed in."
class AlertBanner extends StatelessWidget {
  final String message;
  final AlertTone tone;

  const AlertBanner({super.key, required this.message, this.tone = AlertTone.info});

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, IconData icon) = switch (tone) {
      AlertTone.success => (AppColors.successBg, AppColors.primaryDeep, Icons.check_circle_outline_rounded),
      AlertTone.error => (AppColors.errorBg, const Color(0xFF991B1B), Icons.error_outline_rounded),
      AlertTone.info => (AppColors.infoBg, const Color(0xFF1E40AF), Icons.info_outline_rounded),
      AlertTone.warning => (AppColors.warningBg, const Color(0xFF92400E), Icons.warning_amber_rounded),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, color: foreground))),
          ],
        ),
      ),
    );
  }
}
