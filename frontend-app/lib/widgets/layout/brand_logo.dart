import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme.dart';

/// Mercato logo mark + name, used in headers and on the sign-in screens.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mercato',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('assets/icons/logo_mark.svg', width: size, height: size),
          const SizedBox(width: 10),
          Text('Mercato', style: TextStyle(fontSize: size * 0.56, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.text)),
        ],
      ),
    );
  }
}
