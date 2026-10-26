import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/inputs/app_text_field.dart';

/// Checkout delivery address: a summary card that opens into a form (recipient, email, address).
class DeliveryDetails extends StatelessWidget {
  final bool editing;
  final VoidCallback onEdit;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController address;
  final FocusNode nameFocus;
  final FocusNode emailFocus;
  final FocusNode addressFocus;
  final String? nameError;
  final String? emailError;
  final String? addressError;
  final bool showMissing; // red border + "Some delivery details are missing" on the summary card
  final VoidCallback onChanged;

  const DeliveryDetails({
    super.key,
    required this.editing,
    required this.onEdit,
    required this.name,
    required this.email,
    required this.address,
    required this.nameFocus,
    required this.emailFocus,
    required this.addressFocus,
    required this.nameError,
    required this.emailError,
    required this.addressError,
    required this.showMissing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (editing) {
      return AppCard(
        child: AutofillGroup(
          child: Column(
            children: [
              AppTextField(
                label: 'Recipient name',
                controller: name,
                focusNode: nameFocus,
                hint: 'Full name',
                errorText: nameError,
                maxLength: 120,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Email for updates',
                controller: email,
                focusNode: emailFocus,
                hint: 'you@example.com',
                errorText: emailError,
                maxLength: 255,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Delivery address',
                controller: address,
                focusNode: addressFocus,
                hint: 'Street, district, city',
                errorText: addressError,
                maxLength: 1000,
                maxLines: 3,
                keyboardType: TextInputType.streetAddress,
                autofillHints: const [AutofillHints.fullStreetAddress],
                onChanged: (_) => onChanged(),
              ),
            ],
          ),
        ),
      );
    }

    String orMissing(String value, String missing) => value.trim().isEmpty ? missing : value.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Edit delivery details',
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: BorderSide(color: showMissing ? AppColors.error : AppColors.line, width: 1.5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      child: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(orMissing(name.text, 'Recipient name missing'), style: AppText.head, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(orMissing(email.text, 'Email missing'), style: AppText.meta, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(orMissing(address.text, 'Address missing'), style: AppText.meta, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textFaint),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showMissing)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFB91C1C)),
                SizedBox(width: 6),
                Text('Some delivery details are missing. Tap to edit.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C))),
              ],
            ),
          ),
      ],
    );
  }
}
