import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../buttons/circle_icon_button.dart';
import 'brand_logo.dart';

/// Frame for Sign in, Create account and Reset password: logo (or a back button) on top,
/// scrollable content, and a small note at the bottom. Scrolls naturally when the keyboard is open.
class AuthLayout extends StatelessWidget {
  final bool showBack; // back button instead of the logo
  final List<Widget> children;

  const AuthLayout({super.key, this.showBack = false, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.lg, AppSpacing.page, AppSpacing.xxl),
            child: ConstrainedBox(
              // fill the screen so the footer note sits at the bottom on tall phones
              constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.lg - AppSpacing.xxl),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 56,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: showBack
                            ? CircleIconButton(
                                icon: Icons.chevron_left_rounded,
                                tooltip: 'Back to sign in',
                                onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
                              )
                            : const BrandLogo(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ...children,
                    const Spacer(),
                    const SizedBox(height: AppSpacing.xxxl),
                    const Text('Demo app — please don’t enter real credentials.', style: AppText.meta, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
