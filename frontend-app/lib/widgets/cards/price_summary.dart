import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../utils/formatters.dart';

/// "Subtotal $147.00 / Delivery $4.00 / Total $151.00" rows used by Cart, Checkout and Order details.
class PriceSummary extends StatelessWidget {
  final List<(String, String)> rows; // label, value
  final double total;

  const PriceSummary({super.key, required this.rows, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (i, (label, value)) in rows.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
            child: Row(
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textMuted))),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text, fontFeatures: [FontFeature.tabularFigures()])),
              ],
            ),
          ),
        const SizedBox(height: 14),
        const _DashedLine(),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Expanded(child: Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text))),
            Text(
              formatMoney(total),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.primaryDark, fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: List.generate(
          (constraints.maxWidth / 7).floor(),
          (_) => Container(width: 4, height: 1, margin: const EdgeInsets.only(right: 3), color: const Color(0xFFDDE1DA)),
        ),
      ),
    );
  }
}
