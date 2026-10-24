import 'package:flutter/material.dart';

import '../../widgets/feedback/empty_state.dart';
import '../../widgets/layout/app_header.dart';

/// PLACEHOLDER (slice 1). The real Reset password screen comes in slice 2.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppHeader(title: 'Reset password', backFallback: '/login'),
      body: Center(child: EmptyState(icon: Icons.lock_reset_rounded, title: 'Reset password', message: 'This screen is built in slice 2.')),
    );
  }
}
