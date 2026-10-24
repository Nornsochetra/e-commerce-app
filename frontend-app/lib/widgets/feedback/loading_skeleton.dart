import 'package:flutter/material.dart';

import '../../theme.dart';

/// Grey placeholder box that gently pulses while content is loading.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;
  final double? aspectRatio;

  const SkeletonBox({super.key, this.width, this.height, this.radius = AppSpacing.radiusSm, this.aspectRatio});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = FadeTransition(
      opacity: Tween(begin: 0.55, end: 1.0).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: const Color(0xFFEEF0EB), borderRadius: BorderRadius.circular(widget.radius)),
      ),
    );
    return widget.aspectRatio == null ? box : AspectRatio(aspectRatio: widget.aspectRatio!, child: box);
  }
}

/// Placeholder for a 2-column product grid.
class ProductGridSkeleton extends StatelessWidget {
  final int count;
  const ProductGridSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading products',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.xl,
        crossAxisSpacing: 14,
        childAspectRatio: 0.58,
        children: List.generate(
          count,
          (_) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkeletonBox(aspectRatio: 4 / 5, radius: AppSpacing.radiusLg),
            SizedBox(height: 10),
            SkeletonBox(height: 14, width: 120),
            SizedBox(height: 8),
            SkeletonBox(height: 12, width: 64),
          ]),
        ),
      ),
    );
  }
}

/// Placeholder for a list of horizontal cards.
class ListSkeleton extends StatelessWidget {
  final int count;
  const ListSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Column(
        children: List.generate(
          count,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(children: [
              SkeletonBox(width: 96, height: 112, radius: AppSpacing.radiusMd),
              SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SkeletonBox(height: 12, width: 80),
                  SizedBox(height: 10),
                  SkeletonBox(height: 16, width: 160),
                  SizedBox(height: 36),
                  SkeletonBox(height: 16, width: 60),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
