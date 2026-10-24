import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme.dart';

/// Product photo. Product photos come from the API (URLs); while loading or if the photo
/// can't load, the bundled placeholder (assets/icons/image_placeholder.svg) is shown.
class ProductImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final String? semanticLabel;

  const ProductImage({super.key, required this.url, this.fit = BoxFit.cover, this.semanticLabel});

  static Widget placeholder() => Container(
        color: AppColors.media,
        alignment: Alignment.center,
        child: SvgPicture.asset('assets/icons/image_placeholder.svg', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      );

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      loadingBuilder: (context, child, progress) => progress == null ? child : placeholder(),
      errorBuilder: (context, error, stack) => placeholder(),
    );
  }
}
