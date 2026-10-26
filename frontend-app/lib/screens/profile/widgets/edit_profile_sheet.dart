import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user/user.dart';
import '../../../providers/user/user_provider.dart';
import '../../../theme.dart';
import '../../../utils/validators.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feedback/alert_banner.dart';
import '../../../widgets/feedback/app_bottom_sheet.dart';
import '../../../widgets/feedback/confirm_dialog.dart';
import '../../../widgets/inputs/app_text_field.dart';

/// Opens "Edit profile". Returns true when the profile was saved.
/// Closing with unsaved changes (Cancel, back gesture, tapping outside) asks before discarding them.
Future<bool> showEditProfileSheet(BuildContext context, User user) async {
  final saved = await showAppBottomSheet<bool>(context, title: 'Edit profile', enableDrag: false, child: _EditProfileForm(user: user));
  return saved ?? false;
}

class _EditProfileForm extends StatefulWidget {
  final User user;
  const _EditProfileForm({required this.user});

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _email = TextEditingController(text: widget.user.email);
  late final _phone = TextEditingController(text: widget.user.phone);
  bool _showErrors = false;
  String? _saveError;
  String? _takenEmail; // the server said this email belongs to another account

  bool get _dirty => _name.text != widget.user.name || _email.text != widget.user.email || _phone.text != widget.user.phone;

  Map<String, String> get _errors => {
        'name': ?validateRequired(_name.text, 'Enter your full name.'),
        'email': ?(validateEmail(_email.text) ?? (_email.text.trim().toLowerCase() == _takenEmail ? 'An account with this email already exists.' : null)),
        'phone': ?validatePhone(_phone.text),
      };

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_dirty) {
      final discard = await showConfirmDialog(
        context,
        title: 'Discard changes?',
        message: 'Your edits to this profile haven’t been saved.',
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
    final users = context.read<UserProvider>();
    final result = await users.update(name: _name.text, email: _email.text, phone: _phone.text);
    if (!mounted) return;
    switch (result) {
      case ProfileSaveResult.saved:
        Navigator.pop(context, true);
      case ProfileSaveResult.emailTaken:
        setState(() => _takenEmail = _email.text.trim().toLowerCase());
      case ProfileSaveResult.failed:
        setState(() => _saveError = users.saveError ?? 'We couldn’t save your profile. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<UserProvider>().isSaving;
    final errors = _showErrors ? _errors : const <String, String>{};

    return PopScope(
      canPop: !_dirty || saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AutofillGroup(
        child: Column(
          children: [
            if (_saveError != null) ...[
              AlertBanner(message: _saveError!, tone: AlertTone.error),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppTextField(
              label: 'Full name',
              controller: _name,
              errorText: errors['name'],
              maxLength: 100,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Email',
              controller: _email,
              errorText: errors['email'],
              maxLength: 255,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Phone',
              optional: true,
              controller: _phone,
              hint: '+855 12 345 678',
              errorText: errors['phone'],
              maxLength: 32,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(child: AppButton(label: 'Cancel', variant: AppButtonVariant.outline, onPressed: saving ? null : _close)),
                const SizedBox(width: 10),
                Expanded(child: AppButton(label: saving ? 'Saving…' : 'Save changes', isLoading: saving, onPressed: _dirty ? _save : null)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
