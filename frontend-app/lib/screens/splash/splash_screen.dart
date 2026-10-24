import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth/auth_provider.dart';
import '../../theme.dart';

/// Splash (prototype: splash.html). Loads the saved session while the progress bar fills
/// (at least 1.4 s so the intro can play), then fades into Home (signed in / guest) or Sign in.
/// Tap anywhere or "Skip" to continue sooner. Animations are skipped when Reduce Motion is on.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _minShow = Duration(milliseconds: 1400);

  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  late final _rings = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  double _progress = 0; // 0 → 0.9 while loading, 1.0 when done
  bool _leaving = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_reduceMotion) {
        _intro.value = 1;
      } else {
        _intro.forward();
        _rings.repeat();
      }
      setState(() => _progress = 0.9);
      _start();
    });
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    await Future.wait([auth.init(), Future.delayed(_reduceMotion ? const Duration(milliseconds: 300) : _minShow)]);
    _finish();
  }

  Future<void> _finish() async {
    if (_leaving || !mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.status == AuthStatus.unknown) await auth.init(); // "Skip" tapped before the session loaded
    if (!mounted) return;
    setState(() => _progress = 1);
    await Future.delayed(Duration(milliseconds: _reduceMotion ? 0 : 250));
    if (!mounted) return;
    setState(() => _leaving = true);
    await Future.delayed(Duration(milliseconds: _reduceMotion ? 0 : 320));
    if (mounted) context.go(auth.status == AuthStatus.signedOut ? '/login' : '/home');
  }

  @override
  void dispose() {
    _intro.dispose();
    _rings.dispose();
    super.dispose();
  }

  /// Fade + rise animation for each piece, starting at [start] (0–1) of the intro.
  Widget _reveal(double start, Widget child, {bool scale = false}) {
    final curve = CurvedAnimation(parent: _intro, curve: Interval(start, (start + 0.55).clamp(0, 1), curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: curve,
      child: child,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: scale
            ? Transform.scale(scale: 0.88 + 0.12 * curve.value, child: child)
            : Transform.translate(offset: Offset(0, 10 * (1 - curve.value)), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: AnimatedOpacity(
          opacity: _leaving ? 0 : 1,
          duration: const Duration(milliseconds: 320),
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.16),
                radius: 1.2,
                colors: [Colors.white, AppColors.background, Color(0xFFEDF6F0)],
                stops: [0, 0.55, 1],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // soft mint glow behind the logo
                  Align(
                    alignment: const Alignment(0, -0.32),
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [Color(0x3310B981), Color(0x0010B981)], stops: [0, 0.65]),
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _reveal(0, _Logo(rings: _rings, animate: !_reduceMotion), scale: true),
                        const SizedBox(height: AppSpacing.xxl),
                        _reveal(0.2, const Text('Mercato', style: TextStyle(fontSize: 40, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -1.4, color: AppColors.text))),
                        const SizedBox(height: AppSpacing.sm),
                        _reveal(0.32, const Text('Fresh, simple, delivered.', style: TextStyle(fontSize: 15, color: AppColors.textMuted))),
                        const SizedBox(height: 28),
                        _reveal(0.45, _ProgressBar(value: _progress)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: const StadiumBorder(),
                      elevation: 2,
                      shadowColor: const Color(0x330F172A),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: _finish,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text('Skip', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 28,
                    child: Text('MERCATO · VERSION 1.0', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppColors.textFaint)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient logo mark with two rings that gently pulse outwards.
class _Logo extends StatelessWidget {
  final AnimationController rings;
  final bool animate;
  const _Logo({required this.rings, required this.animate});

  Widget _ring(double offset) => AnimatedBuilder(
        animation: rings,
        builder: (context, _) {
          final t = (rings.value + offset) % 1.0;
          return Opacity(
            opacity: animate ? 0.9 * (1 - t) : 0,
            child: Transform.scale(
              scale: 0.9 + 0.65 * t,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(34), border: Border.all(color: const Color(0x7310B981), width: 1.5)),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mercato logo',
      child: SizedBox.square(
        dimension: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _ring(0),
            _ring(0.5),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Color(0x99047857), blurRadius: 44, spreadRadius: -16, offset: Offset(0, 22))],
              ),
              child: SvgPicture.asset('assets/icons/logo_mark.svg', width: 96, height: 96),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mint track with a green fill that eases to [value] (0–1).
class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading Mercato',
      value: '${(value * 100).round()}%',
      child: Container(
        width: 168,
        height: 6,
        decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(3)),
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: Duration(milliseconds: value >= 1 ? 250 : 1400),
          curve: const Cubic(0.2, 0.7, 0.3, 1),
          width: 168 * value,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
      ),
    );
  }
}
