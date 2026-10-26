import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth/auth_provider.dart';
import '../../services/auth/dev_account.dart';
import '../../theme.dart';
import '../../utils/validators.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/alert_banner.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/layout/auth_layout.dart';

/// Sign in with email + password (prototype: login.html) through POST /auth/login.
/// Debug builds offer the backend's seeded dev account as "Fill in".
class LoginScreen extends StatefulWidget {
  final String? redirectTo; // where to go after signing in (set when a guest opened a protected screen)
  const LoginScreen({super.key, this.redirectTo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _submitted = false; // errors show only after the first Sign in tap
  String? _error; // e.g. wrong password

  String? get _emailError => _submitted ? validateEmail(_email.text) : null;

  String? get _passwordError {
    if (!_submitted) return null;
    if (_password.text.isEmpty) return 'Enter your password.';
    if (_password.text.length < 8) return 'Passwords have at least 8 characters.';
    return null;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _fillDemo() {
    setState(() {
      _email.text = devAccountEmail;
      _password.text = devAccountPassword;
      _error = null;
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_emailError != null) return _emailFocus.requestFocus();
    if (_passwordError != null) return _passwordFocus.requestFocus();

    FocusScope.of(context).unfocus();
    final error = await context.read<AuthProvider>().login(_email.text, _password.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    context.go(widget.redirectTo ?? '/home');
  }

  Future<void> _continueAsGuest() async {
    await context.read<AuthProvider>().continueAsGuest();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return AuthLayout(
      children: [
        const Text('Welcome back', style: AppText.display),
        const SizedBox(height: AppSpacing.xs),
        const Text('Sign in to continue shopping.', style: AppText.bodyMuted),
        const SizedBox(height: AppSpacing.xl),
        if (kDebugMode) ...[
          _DemoAccountBox(onFill: _fillDemo),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (auth.sessionExpired && _error == null) ...[
          const AlertBanner(message: 'Your session has ended. Please sign in again.'),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_error != null) ...[
          AlertBanner(message: _error!, tone: AlertTone.error),
          const SizedBox(height: AppSpacing.lg),
        ],
        AutofillGroup(
          child: Column(
            children: [
              AppTextField(
                label: 'Email',
                controller: _email,
                focusNode: _emailFocus,
                hint: 'you@example.com',
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Password',
                controller: _password,
                focusNode: _passwordFocus,
                hint: 'At least 8 characters',
                errorText: _passwordError,
                isPassword: true,
                maxLength: 72,
                textInputAction: TextInputAction.go,
                autofillHints: const [AutofillHints.password],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _signIn(),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => context.push('/forgot-password'), child: const Text('Forgot password?')),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(label: isLoading ? 'Signing in…' : 'Sign in', isLoading: isLoading, onPressed: _signIn),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'Continue as guest', variant: AppButtonVariant.text, onPressed: isLoading ? null : _continueAsGuest),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('New to APM?', style: AppText.bodyMuted),
            TextButton(onPressed: () => context.push('/register'), child: const Text('Create an account')),
          ],
        ),
      ],
    );
  }
}

/// Mint box showing the dev account with a "Fill in" button (debug builds only).
class _DemoAccountBox extends StatelessWidget {
  final VoidCallback onFill;
  const _DemoAccountBox({required this.onFill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dev account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('$devAccountEmail · $devAccountPassword', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          AppButton(label: 'Fill in', variant: AppButtonVariant.secondary, small: true, expanded: false, onPressed: onFill),
        ],
      ),
    );
  }
}
