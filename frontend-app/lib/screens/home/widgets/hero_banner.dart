import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme.dart';
import '../../../widgets/buttons/app_button.dart';

class _Slide {
  final String eyebrow;
  final String title;
  final String text;
  final String image; // bundled photo (assets/images/banners)
  final String category; // slug opened by the button
  final String cta;
  const _Slide(this.eyebrow, this.title, this.text, this.image, this.category, this.cta);
}

// Same slides as the prototype's Home carousel.
const _slides = [
  _Slide('THE NEW EVERYDAY', 'Good design,\nmade useful.', 'Considered pieces for work and weekends.', 'banner_footwear.jpg', 'footwear', 'Shop footwear'),
  _Slide('CARRY IT WELL', 'Made to go\nwhere you do.', 'Dependable bags for busy days and light travel.', 'banner_bags.jpg', 'bags', 'Shop bags'),
  _Slide('SOUND AND FOCUS', 'Turn down noise.\nKeep the detail.', 'Technology that earns its place in your day.', 'banner_tech.jpg', 'electronics', 'Shop tech'),
  _Slide('FINISHING TOUCH', 'Little things,\nbig difference.', 'Timeless accessories for every season.', 'banner_accessories.jpg', 'accessories', 'Shop accessories'),
];

/// Featured collections carousel on Home. Swipe or tap a dot to change slide; it also moves on
/// by itself every 6 seconds unless the device asks for reduced motion.
class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) return;
    _timer = Timer(const Duration(seconds: 6), () {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage((_index + 1) % _slides.length, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  void _showSlide(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(index);
    } else {
      _controller.animateToPage(index, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Featured collections',
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xxl),
        child: Container(
          height: 228,
          color: AppColors.mintSoft,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _restartTimer();
                },
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
              Positioned(
                left: AppSpacing.md,
                bottom: 6,
                child: Row(
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      Semantics(
                        button: true,
                        selected: i == _index,
                        label: 'Show slide ${i + 1} of ${_slides.length}',
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showSlide(i),
                          child: SizedBox(
                            width: 28,
                            height: 32,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: i == _index ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(color: i == _index ? AppColors.primaryDark : const Color(0xFFA7F3D0), borderRadius: BorderRadius.circular(3)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned(
            right: 14,
            top: 14,
            bottom: 14,
            width: constraints.maxWidth * 0.4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Image.asset('assets/images/banners/${slide.image}', fit: BoxFit.cover, excludeFromSemantics: true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, 0, 40),
            child: SizedBox(
              width: constraints.maxWidth * 0.56 - AppSpacing.xl,
              height: constraints.maxHeight - AppSpacing.xl - 40,
              // Shrinks the text (instead of cutting it off) when large text sizes don't fit.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: constraints.maxWidth * 0.56 - AppSpacing.xl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slide.eyebrow, style: AppText.eyebrow),
                      const SizedBox(height: 6),
                      Text(slide.title, style: const TextStyle(fontSize: 21, height: 26 / 21, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.text)),
                      const SizedBox(height: 6),
                      Text(slide.text, style: const TextStyle(fontSize: 12, height: 18 / 12, color: AppColors.textMuted)),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(label: slide.cta, small: true, expanded: false, onPressed: () => context.go('/categories?category=${slide.category}')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
