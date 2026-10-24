import 'package:flutter/material.dart';

import '../../theme.dart';

/// "−  2  +" control. [max] is the available stock.
class QuantityStepper extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final String? productName; // for screen readers: "Increase quantity of Minimal Watch"

  const QuantityStepper({super.key, required this.value, required this.max, required this.onChanged, this.productName});

  @override
  Widget build(BuildContext context) {
    final of = productName == null ? '' : ' of $productName';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove_rounded, tooltip: 'Decrease quantity$of', onPressed: value > 1 ? () => onChanged(value - 1) : null),
          SizedBox(
            width: 32,
            child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
          ),
          _StepButton(icon: Icons.add_rounded, tooltip: 'Increase quantity$of', onPressed: value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _StepButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onPressed == null ? Colors.transparent : AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(dimension: 36, child: Icon(icon, size: 18, color: onPressed == null ? AppColors.textFaint : AppColors.text)),
        ),
      ),
    );
  }
}
