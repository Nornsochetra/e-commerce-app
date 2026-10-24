import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/user/user_provider.dart';
import '../../theme.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/layout/app_header.dart';

/// PLACEHOLDER (slice 1): profile name, My orders and Log out so the flows can be tested.
/// The full profile (edit sheet, menus, reset demo data) comes in slice 5.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    return Scaffold(
      appBar: const AppHeader(title: 'Profile', showBack: false),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          Row(children: [
            CircleAvatar(radius: 32, backgroundColor: AppColors.mint, child: Text(user?.initials ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryDeep))),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.name ?? '', style: AppText.section),
                Text(user?.email ?? '', style: AppText.meta),
              ]),
            ),
          ]),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(label: 'My orders', variant: AppButtonVariant.outline, icon: Icons.inventory_2_outlined, onPressed: () => context.push('/orders')),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Reset demo data',
            variant: AppButtonVariant.outline,
            icon: Icons.refresh_rounded,
            onPressed: () async {
              await resetDemoData();
              if (context.mounted) context.go('/splash');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Log out',
            variant: AppButtonVariant.danger,
            icon: Icons.logout_rounded,
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
