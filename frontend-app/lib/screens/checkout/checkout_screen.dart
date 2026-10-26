import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/cart/cart_provider.dart';
import '../../providers/notification/notification_provider.dart';
import '../../providers/order/order_provider.dart';
import '../../providers/user/user_provider.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/cards/price_summary.dart';
import '../../widgets/cards/product_image.dart';
import '../../widgets/feedback/alert_banner.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/status_badge.dart';
import '../../widgets/layout/action_dock.dart';
import '../../widgets/layout/app_header.dart';
import 'widgets/delivery_details.dart';

/// SCR-015 Checkout: delivery address (view / edit), payment method, order review and a Place order dock.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // One key per checkout visit: retrying after an error can never create a second order.
  final _idempotencyKey = 'checkout-${DateTime.now().microsecondsSinceEpoch}';
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _address;
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _addressFocus = FocusNode();
  bool _editing = false;
  bool _showErrors = false;
  String? _placeError;

  @override
  void initState() {
    super.initState();
    // Prefill from the profile and the address of the last order.
    final user = context.read<UserProvider>().user;
    final orders = context.read<OrderProvider>().orders;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _address = TextEditingController(text: orders.isEmpty ? '' : orders.first.address);
    _editing = _errors.isNotEmpty; // open the form straight away when something is missing
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _address]) {
      c.dispose();
    }
    for (final f in [_nameFocus, _emailFocus, _addressFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _errors => {
        'name': ?validateRequired(_name.text, 'Enter the recipient’s name.'),
        'email': ?validateEmail(_email.text),
        'address': ?validateAddress(_address.text),
      };

  Future<void> _placeOrder() async {
    final errors = _errors;
    if (errors.isNotEmpty) {
      setState(() {
        _showErrors = true;
        _editing = true;
      });
      final first = errors.containsKey('name') ? _nameFocus : (errors.containsKey('email') ? _emailFocus : _addressFocus);
      WidgetsBinding.instance.addPostFrameCallback((_) => first.requestFocus());
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _placeError = null);
    final cart = context.read<CartProvider>();
    final orders = context.read<OrderProvider>();
    final notifications = context.read<NotificationProvider>();
    if (orders.isPlacing) return; // double tap

    final order = await orders.placeOrder(
      idempotencyKey: _idempotencyKey,
      items: cart.items,
      recipientName: _name.text,
      email: _email.text,
      address: _address.text,
    );
    if (!mounted) return;
    if (order == null) {
      setState(() => _placeError = 'We couldn’t place your order. Check your connection and try again — you won’t be charged twice.');
      return;
    }
    // go() replaces checkout, so Back from the confirmation can't return to an empty checkout.
    context.go('/orders/${order.id}/confirmed');
    await cart.clear();
    await notifications.load(); // the new "Order confirmed" notification
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final placing = context.watch<OrderProvider>().isPlacing;
    const header = AppHeader(title: 'Checkout', backFallback: '/cart');

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: header,
        body: ListView(children: [
          EmptyState(icon: Icons.shopping_bag_outlined, title: 'Your cart is empty', message: 'Add products to your cart before checking out.', actionLabel: 'Browse products', onAction: () => context.go('/categories')),
        ]),
      );
    }

    final errors = _showErrors ? _errors : const <String, String>{};
    final total = cart.subtotal + cart.deliveryFee;

    return Scaffold(
      appBar: header,
      body: AbsorbPointer(
        absorbing: placing,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, AppSpacing.xxl),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            if (_placeError != null) ...[
              AlertBanner(message: _placeError!, tone: AlertTone.error),
              const SizedBox(height: AppSpacing.lg),
            ],
            _SectionTitle('Delivery address', action: _editing ? 'Done' : 'Edit', onAction: () => setState(() => _editing = !_editing)),
            DeliveryDetails(
              editing: _editing,
              onEdit: () => setState(() => _editing = true),
              name: _name,
              email: _email,
              address: _address,
              nameFocus: _nameFocus,
              emailFocus: _emailFocus,
              addressFocus: _addressFocus,
              nameError: errors['name'],
              emailError: errors['email'],
              addressError: errors['address'],
              showMissing: _showErrors && errors.isNotEmpty,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionTitle('Payment'),
            const _PaymentOptions(),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionTitle('Your order'),
            AppCard(
              child: Column(
                children: [
                  for (final item in cart.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        children: [
                          SizedBox.square(dimension: 56, child: ClipRRect(borderRadius: BorderRadius.circular(AppSpacing.radiusSm), child: ProductImage(url: item.imageUrl))),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: AppText.head, maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('Qty ${item.quantity} · ${formatMoney(item.unitPrice)}', style: AppText.meta),
                              ],
                            ),
                          ),
                          Text(formatMoney(item.lineTotal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
                        ],
                      ),
                    ),
                  const Divider(height: AppSpacing.lg),
                  const SizedBox(height: AppSpacing.xs),
                  PriceSummary(
                    rows: [
                      ('Subtotal', formatMoney(cart.subtotal)),
                      ('Standard delivery · 2–4 days', formatMoney(cart.deliveryFee)),
                    ],
                    total: total,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Row(
              children: [
                SizedBox(width: AppSpacing.xs),
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Prices and totals are checked again when your order is placed.', style: AppText.meta)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: ActionDock(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              Text(formatMoney(total), style: AppText.price.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: AppButton(label: placing ? 'Placing…' : 'Place order', isLoading: placing, onPressed: _placeOrder)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const _SectionTitle(this.text, {this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(child: Semantics(header: true, child: Text(text, style: AppText.section))),
              if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
            ],
          ),
        ),
      );
}

/// Cash on delivery (the only v1 method) and a disabled card option marked "Soon".
class _PaymentOptions extends StatelessWidget {
  const _PaymentOptions();

  @override
  Widget build(BuildContext context) {
    Widget option({required bool selected, required String title, required String subtitle, required Widget trailing}) => Semantics(
          inMutuallyExclusiveGroup: true,
          checked: selected,
          enabled: selected,
          child: Opacity(
            opacity: selected ? 1 : 0.55,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? AppColors.mintSoft : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.primaryDark : null,
                      border: Border.all(color: selected ? AppColors.primaryDark : const Color(0xFFCBD5E1), width: 2),
                    ),
                    child: selected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(title, style: AppText.head), Text(subtitle, style: AppText.meta)],
                    ),
                  ),
                  trailing,
                ],
              ),
            ),
          ),
        );

    return Column(
      children: [
        option(
          selected: true,
          title: 'Cash on delivery',
          subtitle: 'Pay the courier when your order arrives',
          trailing: const Icon(Icons.payments_outlined, size: 22, color: AppColors.primaryDark),
        ),
        const SizedBox(height: 10),
        option(selected: false, title: 'Credit / debit card', subtitle: 'Not available in this version', trailing: const StatusBadge(label: 'Soon')),
      ],
    );
  }
}
