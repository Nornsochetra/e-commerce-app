import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../providers/auth/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/layout/brand_logo.dart';

/// PLACEHOLDER (slice 1): one-tap demo sign-in and guest access so navigation can be tested.
/// The real form (email, password, validation) comes in slice 2.
class LoginScreen extends StatelessWidget {
  final String? redirectTo; // where to go after signing in (set when a guest opened a protected screen)
  const LoginScreen({super.key, this.redirectTo});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            const Align(alignment: Alignment.centerLeft, child: BrandLogo()),
            const SizedBox(height: AppSpacing.xxxl),
            const Text('Welcome back', style: AppText.display),
            const SizedBox(height: AppSpacing.xs),
            const Text('Placeholder sign-in. The full form comes in slice 2.', style: AppText.bodyMuted),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Sign in with demo account',
              isLoading: auth.isLoading,
              onPressed: () async {
                final error = await context.read<AuthProvider>().login(demoEmail, demoPassword);
                if (!context.mounted) return;
                if (error != null) return showAppToast(context, error);
                context.go(redirectTo ?? '/home');
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Continue as guest',
              variant: AppButtonVariant.outline,
              onPressed: () async {
                await context.read<AuthProvider>().continueAsGuest();
                if (context.mounted) context.go('/home');
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(onPressed: () => context.push('/register'), child: const Text('Create an account')),
            TextButton(onPressed: () => context.push('/forgot-password'), child: const Text('Forgot password?')),
          ],
        ),
      ),
    );
  }
}
