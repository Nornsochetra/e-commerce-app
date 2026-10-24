import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../utils/validators.dart';

/// Four bars + "Strength: Good" under the password field on Create account.
class PasswordStrength extends StatelessWidget {
  final String password;
  const PasswordStrength({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final score = passwordStrength(password);
    final tooShort = password.length < 8;
    final label = tooShort ? 'Too short' : const ['Too short', 'Weak', 'Fair', 'Good', 'Strong'][score];
    final color = score <= 1 ? AppColors.error : (score == 2 ? AppColors.star : AppColors.primary);

    return Semantics(
      label: 'Password strength: $label',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 4; i++) ...[
                if (i > 1) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    decoration: BoxDecoration(color: i <= score ? color : AppColors.line, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Strength: $label', style: AppText.meta),
        ],
      ),
    );
  }
}
