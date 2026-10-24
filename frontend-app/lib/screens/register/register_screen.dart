import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/user/user_provider.dart';
import '../../theme.dart';
import '../../utils/validators.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/alert_banner.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/layout/auth_layout.dart';
import 'widgets/password_strength.dart';

/// Create account (prototype: register.html). The user is signed in right away (no email verification in v1).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _focus = List.generate(5, (_) => FocusNode()); // name, email, phone, password, confirm

  bool _submitted = false;
  String? _error;

  String? _errorFor(int field) {
    if (!_submitted) return null;
    return switch (field) {
      0 => validateRequired(_name.text, 'Enter your full name.'),
      1 => validateEmail(_email.text),
      2 => validatePhone(_phone.text),
      3 => validatePassword(_password.text),
      _ => _confirm.text.isEmpty ? 'Confirm your password.' : (_confirm.text != _password.text ? 'Passwords do not match.' : null),
    };
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _createAccount() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    for (var i = 0; i < 5; i++) {
      if (_errorFor(i) != null) return _focus[i].requestFocus();
    }

    FocusScope.of(context).unfocus();
    final error = await context.read<AuthProvider>().register(name: _name.text, email: _email.text, phone: _phone.text, password: _password.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    await context.read<UserProvider>().load(); // show the new name on Profile
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    void refresh(String _) => setState(() {});

    return AuthLayout(
      showBack: true,
      children: [
        const Text('Create account', style: AppText.display),
        const SizedBox(height: AppSpacing.xs),
        const Text('Join Mercato — you’ll be signed in right away.', style: AppText.bodyMuted),
        const SizedBox(height: AppSpacing.xxl),
        if (_error != null) ...[
          AlertBanner(message: _error!, tone: AlertTone.error),
          const SizedBox(height: AppSpacing.lg),
        ],
        AutofillGroup(
          child: Column(
            children: [
              AppTextField(
                label: 'Full name',
                controller: _name,
                focusNode: _focus[0],
                hint: 'Alex Morgan',
                errorText: _errorFor(0),
                maxLength: 100,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                onChanged: refresh,
                onSubmitted: (_) => _focus[1].requestFocus(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Email',
                controller: _email,
                focusNode: _focus[1],
                hint: 'you@example.com',
                errorText: _errorFor(1),
                maxLength: 255,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: refresh,
                onSubmitted: (_) => _focus[2].requestFocus(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Phone',
                optional: true,
                controller: _phone,
                focusNode: _focus[2],
                hint: '+855 12 345 678',
                errorText: _errorFor(2),
                maxLength: 32,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                onChanged: refresh,
                onSubmitted: (_) => _focus[3].requestFocus(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Password',
                controller: _password,
                focusNode: _focus[3],
                hint: 'At least 8 characters',
                errorText: _errorFor(3),
                helperText: _password.text.isEmpty ? 'Use 8+ characters. Mixing letters, numbers and symbols makes it stronger.' : null,
                isPassword: true,
                maxLength: 72,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: refresh,
                onSubmitted: (_) => _focus[4].requestFocus(),
              ),
              if (_password.text.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                PasswordStrength(password: _password.text),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Confirm password',
                controller: _confirm,
                focusNode: _focus[4],
                hint: 'Repeat your password',
                errorText: _errorFor(4),
                isPassword: true,
                maxLength: 72,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: refresh,
                onSubmitted: (_) => _createAccount(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(label: isLoading ? 'Creating account…' : 'Create account', isLoading: isLoading, onPressed: _createAccount),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Already have an account?', style: AppText.bodyMuted),
            TextButton(onPressed: () => context.canPop() ? context.pop() : context.go('/login'), child: const Text('Sign in')),
          ],
        ),
      ],
    );
  }
}
