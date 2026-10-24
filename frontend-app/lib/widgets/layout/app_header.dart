import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../buttons/circle_icon_button.dart';

/// Screen header: round back button on the left, centred title (+ optional subtitle), optional action on the right.
/// Use it as `Scaffold(appBar: AppHeader(...))`.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool showBack;
  final String? backFallback; // where Back goes when there is no previous screen, e.g. '/home'
  final Widget? leading; // replaces the back button (e.g. the logo on Home)
  final Widget? trailing;

  const AppHeader({super.key, this.title, this.subtitle, this.showBack = true, this.backFallback, this.leading, this.trailing});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(backFallback ?? '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = showBack && (context.canPop() || backFallback != null);
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: leading != null
                ? Row(children: [leading!, const Spacer(), ?trailing])
                : Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: canGoBack ? CircleIconButton(icon: Icons.chevron_left_rounded, tooltip: 'Go back', onPressed: () => _goBack(context)) : null,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (title != null) Text(title!, style: AppText.headerTitle, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                            if (subtitle != null) Text(subtitle!, style: AppText.meta, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(width: 44, child: trailing),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
