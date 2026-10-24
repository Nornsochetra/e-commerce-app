import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/layout/brand_logo.dart';

/// PLACEHOLDER (slice 1): loads the saved session, then opens Home or Login.
/// The full splash design (rings, tagline, progress bar) comes in slice 2.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    await Future.wait([auth.init(), Future.delayed(const Duration(milliseconds: 900))]);
    if (!mounted) return;
    context.go(auth.status == AuthStatus.signedOut ? '/login' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BrandLogo(size: 56),
          SizedBox(height: AppSpacing.md),
          Text('Fresh, simple, delivered.', style: AppText.bodyMuted),
          SizedBox(height: AppSpacing.xxl),
          SizedBox(width: 160, child: LinearProgressIndicator(minHeight: 6, borderRadius: BorderRadius.all(Radius.circular(3)))),
        ]),
      ),
    );
  }
}
