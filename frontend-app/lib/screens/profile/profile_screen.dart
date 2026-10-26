import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/cart/cart_provider.dart';
import '../../providers/notification/notification_provider.dart';
import '../../providers/order/order_provider.dart';
import '../../providers/user/user_provider.dart';
import '../../providers/wishlist/wishlist_provider.dart';
import '../../theme.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/buttons/circle_icon_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/feedback/confirm_dialog.dart';
import '../../widgets/feedback/loading_skeleton.dart';
import '../../widgets/feedback/status_badge.dart';
import '../../widgets/layout/app_header.dart';
import '../../utils/on_screen.dart';
import 'widgets/edit_profile_sheet.dart';

/// SCR-005/006 Profile: details with an Edit sheet, order / wishlist / cart counts, shopping links,
/// deferred items marked "Soon", and Log out (confirmed first).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _edit(BuildContext context) async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    final saved = await showEditProfileSheet(context, user);
    if (saved && context.mounted) showAppToast(context, 'Profile updated');
  }

  Future<void> _logOut(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Log out of APM?',
      message: 'You’ll return to the sign-in screen. Your cart and wishlist stay saved in your account.',
      confirmLabel: 'Log out',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>();
    final user = users.user;
    // The numbers come from GET /auth/me until a screen has loaded the list itself, so opening
    // Profile doesn't download orders, wishlist and cart.
    final counts = users.counts;
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.orders;
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.watch<CartProvider>();
    final orderCount = orderProvider.isLoaded ? orderProvider.totalOrders : counts.orders;
    final saved = wishlist.isLoaded ? wishlist.total : counts.wishlistItems;
    final inCart = cart.isLoaded ? cart.itemCount : counts.cartItems;
    loadWhenOnScreen(context, context.read<NotificationProvider>().ensureUnreadCount);
    final unread = context.watch<NotificationProvider>().unreadCount;
    final active = orders.where((o) => o.isActive).length;

    return Scaffold(
      appBar: AppHeader(
        title: 'Profile',
        showBack: false,
        trailing: CircleIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
          badgeCount: unread,
          onPressed: () => context.go('/notifications'),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
        children: [
          if (user == null && users.error != null)
            AppCard(
              child: Column(
                children: [
                  Text(users.error!, style: AppText.bodyMuted, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(label: 'Try again', variant: AppButtonVariant.outline, small: true, expanded: false, onPressed: users.load),
                ],
              ),
            )
          else if (user == null)
            const ListSkeleton(count: 1)
          else
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                    child: ExcludeSemantics(child: Text(user.initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryDeep))),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: AppText.section, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(user.email, style: AppText.meta.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(user.phone.isEmpty ? 'No phone number' : user.phone, style: AppText.meta),
                        Text('Member since ${user.memberSince.year}', style: AppText.meta),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(label: 'Edit', icon: Icons.edit_outlined, variant: AppButtonVariant.secondary, small: true, expanded: false, onPressed: () => _edit(context)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Stat(value: orderCount, label: 'Orders', onTap: () => context.push('/orders')),
              const SizedBox(width: 10),
              _Stat(value: saved, label: 'Saved', onTap: () => context.go('/wishlist')),
              const SizedBox(width: 10),
              _Stat(value: inCart, label: 'In cart', onTap: () => context.go('/cart')),
            ],
          ),

          const _Label('Shopping'),
          _Menu(rows: [
            _MenuRow(icon: Icons.inventory_2_outlined, title: 'My orders', subtitle: active > 0 ? '$active in progress' : 'Track and review orders', onTap: () => context.push('/orders')),
            _MenuRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Order updates and offers',
              badge: unread > 0 ? '$unread new' : null,
              onTap: () => context.go('/notifications'),
            ),
            _MenuRow(icon: Icons.favorite_border_rounded, title: 'Wishlist', subtitle: 'Products you saved', onTap: () => context.go('/wishlist')),
          ]),

          const _Label('More'),
          _Menu(rows: [
            const _MenuRow(icon: Icons.settings_outlined, title: 'Settings', neutral: true),
            const _MenuRow(icon: Icons.help_outline_rounded, title: 'About APM', neutral: true),
            const _MenuRow(icon: Icons.call_outlined, title: 'Contact us', neutral: true),
          ]),

          const SizedBox(height: AppSpacing.xxl),
          AppButton(label: 'Log out', icon: Icons.logout_rounded, variant: AppButtonVariant.danger, onPressed: () => _logOut(context)),
          const SizedBox(height: AppSpacing.md),
          const Text('APM demo · data stays on this device', style: AppText.meta, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback onTap;
  const _Stat({required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: '$value $label',
        excludeSemantics: true,
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), side: const BorderSide(color: AppColors.line)),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpacing.sm),
              child: Column(
                children: [
                  Text('$value', style: const TextStyle(fontSize: 20, height: 24 / 20, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xxl, AppSpacing.xs, AppSpacing.sm),
        child: Semantics(header: true, child: Text(text.toUpperCase(), style: AppText.meta.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.7))),
      );
}

/// White card holding [_MenuRow]s separated by hairlines.
class _Menu extends StatelessWidget {
  final List<_MenuRow> rows;
  const _Menu({required this.rows});

  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final (i, row) in rows.indexed) ...[
              if (i > 0) const Divider(height: 1),
              row,
            ],
          ],
        ),
      );
}

/// Menu row: icon tile, title and subtitle, optional badge, chevron. Without [onTap] it is shown as "Soon".
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final bool neutral; // grey icon tile
  final VoidCallback? onTap;

  const _MenuRow({required this.icon, required this.title, this.subtitle, this.badge, this.neutral = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final soon = onTap == null;
    return Semantics(
      button: !soon,
      enabled: !soon,
      label: soon ? '$title, coming soon' : null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: neutral ? AppColors.field : AppColors.mintSoft, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  child: Icon(icon, size: 20, color: neutral ? const Color(0xFF475569) : AppColors.primaryDark),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.head.copyWith(color: soon ? AppColors.textMuted : AppColors.text)),
                      if (subtitle != null) Text(subtitle!, style: AppText.meta),
                    ],
                  ),
                ),
                if (soon)
                  const StatusBadge(label: 'Soon')
                else ...[
                  if (badge != null) ...[StatusBadge(label: badge!, tone: BadgeTone.success), const SizedBox(width: AppSpacing.sm)],
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textFaint),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
