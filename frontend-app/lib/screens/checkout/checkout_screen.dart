import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/order/checkout.dart';
import '../../models/order/order_item.dart';
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

/// SCR-015 Checkout: delivery address (view / edit), payment method, order review with the totals the
/// server calculates (POST /orders/preview) and a Place order dock (POST /orders with an Idempotency-Key).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _address;
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _addressFocus = FocusNode();
  bool _editing = false;
  bool _showErrors = false;
  String? _placeError;
  bool _cartProblem = false; // stock or empty cart: offer "Review cart"

  CheckoutPreview? _preview; // totals calculated by the server for the current details
  bool _previewing = false;

  // One Idempotency-Key per set of delivery details: retrying the same details can never create a
  // second order, and changed details get a new key (the server rejects a reused key with new details).
  String? _idempotencyKey;
  Delivery? _keyFor;

  @override
  void initState() {
    super.initState();
    // Prefill from the profile and, when known, the address of the last order.
    final user = context.read<UserProvider>().user;
    final orders = context.read<OrderProvider>();
    final last = orders.orders.isEmpty ? null : orders.orderById(orders.orders.first.id);
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _address = TextEditingController(text: last?.address ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillAndPreview());
  }

  /// Reads the last order (for its address) if needed, then asks the server for the totals.
  Future<void> _prefillAndPreview() async {
    final orders = context.read<OrderProvider>();
    await Future.wait([context.read<CartProvider>().ensureLoaded(), orders.ensureLoaded()]);
    if (!mounted) return;
    if (_address.text.isEmpty && orders.orders.isNotEmpty) {
      final lastId = orders.orders.first.id;
      await orders.loadOrder(lastId);
      final address = orders.orderById(lastId)?.address;
      if (!mounted) return;
      if (_address.text.isEmpty && address != null) _address.text = address;
    }
    if (!mounted) return;
    setState(() => _editing = _errors.isNotEmpty); // open the form straight away when something is missing
    await _refreshPreview();
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

  Delivery get _delivery => Delivery(recipientName: _name.text, email: _email.text, address: _address.text);

  /// Asks the server what the current cart will cost (needs complete delivery details).
  Future<void> _refreshPreview() async {
    if (_errors.isNotEmpty) return;
    setState(() => _previewing = true);
    final (preview, problem) = await context.read<OrderProvider>().preview(_delivery);
    if (!mounted) return;
    setState(() {
      _previewing = false;
      _preview = preview;
      _placeError = problem?.userMessage;
      _cartProblem = problem?.code == 'INSUFFICIENT_STOCK' || problem?.code == 'CART_EMPTY';
    });
  }

  void _toggleEditing() {
    final wasEditing = _editing;
    setState(() => _editing = !_editing);
    if (wasEditing) _refreshPreview(); // "Done": recalculate for the new details
  }

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

    final delivery = _delivery;
    if (_idempotencyKey == null || _keyFor != delivery) {
      _idempotencyKey = 'checkout-${DateTime.now().microsecondsSinceEpoch}';
      _keyFor = delivery;
    }
    final (order, problem) = await orders.placeOrder(delivery, idempotencyKey: _idempotencyKey!);
    if (!mounted) return;
    if (order == null) {
      if (problem == null) return; // a second tap while the first was still placing
      if (problem.code == 'CONFLICT') _idempotencyKey = null; // details changed: the next try gets a new key
      setState(() {
        _placeError = problem.isConnectionProblem ? '${problem.userMessage} Trying again won’t create a second order.' : problem.userMessage;
        _cartProblem = problem.code == 'INSUFFICIENT_STOCK' || problem.code == 'CART_EMPTY';
      });
      if (_cartProblem) cart.load(); // show the current stock in the cart
      return;
    }
    // go() replaces checkout, so Back from the confirmation can't return to an empty checkout.
    context.go('/orders/${order.id}/confirmed');
    cart.load(); // the server already removed the ordered items
    notifications.load(); // and created the "Order placed" notification
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final placing = context.watch<OrderProvider>().isPlacing;
    const header = AppHeader(title: 'Checkout', backFallback: '/cart');

    if (cart.items.isEmpty && !placing) {
      return Scaffold(
        appBar: header,
        body: ListView(children: [
          EmptyState(icon: Icons.shopping_bag_outlined, title: 'Your cart is empty', message: 'Add products to your cart before checking out.', actionLabel: 'Browse products', onAction: () => context.go('/categories')),
        ]),
      );
    }

    final errors = _showErrors ? _errors : const <String, String>{};
    final preview = _preview;
    // Until the server has calculated the totals, the cart's numbers are shown as an estimate.
    final lines = preview?.items ??
        [for (final i in cart.items) OrderItem(productId: i.productId, name: i.name, imageUrl: i.imageUrl, unitPrice: i.unitPrice, quantity: i.quantity, lineTotal: i.lineTotal)];
    final subtotal = preview?.subtotal ?? cart.subtotal;
    final deliveryFee = preview?.deliveryFee ?? standardDeliveryFeeUsd;
    final total = preview?.total ?? subtotal + deliveryFee;

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
              if (_cartProblem) Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => context.go('/cart'), child: const Text('Review cart'))),
              const SizedBox(height: AppSpacing.lg),
            ],
            _SectionTitle('Delivery address', action: _editing ? 'Done' : 'Edit', onAction: _toggleEditing),
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
                  if (_previewing) const Padding(padding: EdgeInsets.only(bottom: AppSpacing.md), child: LinearProgressIndicator(minHeight: 2)),
                  for (final item in lines)
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
                      ('Subtotal', formatMoney(subtotal)),
                      ('Standard delivery · 2–4 days', formatMoney(deliveryFee)),
                    ],
                    total: total,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    preview != null ? 'Totals calculated by APM for your current cart.' : 'Estimated totals. They are calculated once your delivery details are complete.',
                    style: AppText.meta,
                  ),
                ),
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
