import 'package:flutter/material.dart';

import '../../widgets/feedback/empty_state.dart';
import '../../widgets/layout/app_header.dart';

/// PLACEHOLDER (slice 1). The real Create account screen comes in slice 2.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppHeader(title: 'Create account', backFallback: '/login'),
      body: Center(child: EmptyState(icon: Icons.person_add_alt_1_rounded, title: 'Create account', message: 'This screen is built in slice 2.')),
    );
  }
}
