import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth/auth_provider.dart';
import '../../../theme.dart';
import '../../../utils/validators.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feedback/alert_banner.dart';
import '../../../widgets/feedback/app_bottom_sheet.dart';
import '../../../widgets/feedback/confirm_dialog.dart';
import '../../../widgets/inputs/app_text_field.dart';

/// Opens "Change password". Returns true when the password was changed.
/// Other devices are signed out by the server; this one stays signed in.
/// Closing with something typed (Cancel, back gesture, tapping outside) asks before discarding it.
///
/// Autofill is off on purpose: in a browser, an AutofillGroup keeps hidden inputs for every field,
/// and the password manager (saved or suggested passwords) writes into them, refilling fields the
/// user has just cleared.
Future<bool> showChangePasswordSheet(BuildContext context) async {
  final changed = await showAppBottomSheet<bool>(context, title: 'Change password', enableDrag: false, child: const _ChangePasswordForm());
  return changed ?? false;
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm();

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showErrors = false;
  String? _saveError;
  String? _wrongCurrent; // the server said this current password is wrong

  bool get _dirty => _current.text.isNotEmpty || _password.text.isNotEmpty || _confirm.text.isNotEmpty;

  Map<String, String> get _errors => {
        'current': ?(validateRequired(_current.text, 'Enter your current password.') ?? (_current.text == _wrongCurrent ? 'Your current password isn’t right.' : null)),
        'password': ?(validatePassword(_password.text) ?? (_password.text == _current.text ? 'Choose a password different from your current one.' : null)),
        'confirm': ?(_confirm.text.isEmpty ? 'Confirm your new password.' : (_confirm.text != _password.text ? 'Passwords do not match.' : null)),
      };

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_dirty) {
      final discard = await showConfirmDialog(
        context,
        title: 'Discard changes?',
        message: 'Your password hasn’t been changed.',
        cancelLabel: 'Keep editing',
        confirmLabel: 'Discard',
        danger: true,
      );
      if (!discard || !mounted) return;
    }
    Navigator.pop(context, false);
  }

  Future<void> _save() async {
    setState(() {
      _showErrors = true;
      _saveError = null;
    });
    if (_errors.isNotEmpty) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.changePassword(currentPassword: _current.text, newPassword: _password.text);
    if (!mounted) return;
    switch (result) {
      case PasswordChangeResult.changed:
        Navigator.pop(context, true);
      case PasswordChangeResult.wrongPassword:
        setState(() => _wrongCurrent = _current.text);
      case PasswordChangeResult.failed:
        setState(() => _saveError = auth.passwordError ?? 'We couldn’t change your password. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<AuthProvider>().isChangingPassword;
    final errors = _showErrors ? _errors : const <String, String>{};

    return PopScope(
      canPop: !_dirty || saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Column(
        children: [
          if (_saveError != null) ...[
            AlertBanner(message: _saveError!, tone: AlertTone.error),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppTextField(
            label: 'Current password',
            controller: _current,
            errorText: errors['current'],
            isPassword: true,
            maxLength: 72,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'New password',
            controller: _password,
            hint: 'At least 8 characters',
            errorText: errors['password'],
            isPassword: true,
            maxLength: 72,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Confirm new password',
            controller: _confirm,
            hint: 'Repeat your new password',
            errorText: errors['confirm'],
            isPassword: true,
            maxLength: 72,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('You’ll stay signed in here. Other devices will need to sign in again.', style: AppText.meta),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: AppButton(label: 'Cancel', variant: AppButtonVariant.outline, onPressed: saving ? null : _close),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(label: saving ? 'Saving…' : 'Change password', isLoading: saving, onPressed: _dirty ? _save : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
