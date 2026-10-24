import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/cart/cart_provider.dart';
import '../../theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/inputs/quantity_stepper.dart';
import '../../widgets/layout/app_header.dart';

/// PLACEHOLDER (slice 1): items with quantity steppers and the total, so cart state can be tested.
/// The full cart (photos, remove with undo, summary card, checkout dock) comes in slice 4.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppHeader(title: 'My Cart', subtitle: cart.itemCount == 0 ? null : '${cart.itemCount} items', showBack: false),
      body: cart.items.isEmpty
          ? Center(child: EmptyState(icon: Icons.shopping_bag_outlined, title: 'Your cart is empty', message: 'Browse the shop and tap Add on anything you like.', actionLabel: 'Start shopping', onAction: () => context.go('/categories')))
          : ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, MediaQuery.paddingOf(context).bottom + AppSpacing.xxl),
              children: [
                for (final item in cart.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(children: [
                      Expanded(child: Text(item.name, style: AppText.head)),
                      QuantityStepper(value: item.quantity, max: item.availableQuantity, productName: item.name, onChanged: (q) => cart.setQuantity(item.productId, q)),
                    ]),
                  ),
                const Divider(height: AppSpacing.xxxl),
                Row(children: [const Expanded(child: Text('Total', style: AppText.section)), Text(formatMoney(cart.total), style: AppText.price.copyWith(fontSize: 22, color: AppColors.primaryDark))]),
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: 'Checkout', onPressed: () => context.push('/checkout')),
              ],
            ),
    );
  }
}
