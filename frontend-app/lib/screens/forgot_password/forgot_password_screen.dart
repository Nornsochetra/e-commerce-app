import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth/auth_provider.dart';
import '../../theme.dart';
import '../../utils/validators.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/alert_banner.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/layout/auth_layout.dart';

/// Reset password (prototype: forgot-password.html). Always shows the same confirmation,
/// so the app never reveals whether an account exists (requirement.md §7.1).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _emailFocus = FocusNode();
  bool _submitted = false;
  bool _sending = false;
  bool _sent = false;

  String? get _emailError => _submitted ? validateEmail(_email.text) : null;

  @override
  void dispose() {
    _email.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _submitted = true);
    if (_emailError != null) return _emailFocus.requestFocus();
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    await context.read<AuthProvider>().requestPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: true,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            child: Icon(_sent ? Icons.mark_email_read_outlined : Icons.lock_outline_rounded, color: AppColors.primaryDark),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(_sent ? 'Check your email' : 'Reset password', style: AppText.display),
        const SizedBox(height: AppSpacing.sm),
        if (_sent) ...[
          Text.rich(
            TextSpan(style: AppText.bodyMuted, children: [
              const TextSpan(text: 'If an account exists for '),
              TextSpan(text: _email.text.trim(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
              const TextSpan(text: ', we’ve sent instructions to reset the password.'),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),
          const AlertBanner(message: 'Demo app: no real email is sent yet.', tone: AlertTone.info),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(label: 'Back to sign in', onPressed: () => context.go('/login')),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: 'Use a different email', variant: AppButtonVariant.text, onPressed: () => setState(() => _sent = false)),
        ] else ...[
          const Text('Enter the email you use for Mercato and we’ll send reset instructions.', style: AppText.bodyMuted),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            label: 'Email',
            controller: _email,
            focusNode: _emailFocus,
            hint: 'you@example.com',
            errorText: _emailError,
            maxLength: 255,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(label: _sending ? 'Sending…' : 'Send instructions', isLoading: _sending, onPressed: _send),
        ],
      ],
    );
  }
}
