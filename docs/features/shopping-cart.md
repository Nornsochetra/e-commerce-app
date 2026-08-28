# Shopping Cart

## 1. Overview

The shopping-cart feature allows users to collect products intended for purchase, change quantities, remove items, and continue toward checkout.

## 2. Goals

- Make cart contents and totals easy to understand.
- Allow quantities to be changed safely.
- Allow unwanted items to be removed.
- Provide a clear transition to checkout.

## 3. Actor

- Authenticated user

## 4. Screen

### 4.1 Shopping Cart

- Display cart items and their approved summary information.
- Display quantity controls and removal actions.
- Display approved totals.
- Provide navigation to checkout when the cart is eligible.

Adding an item, updating quantity, and removing an item are interactions rather than separate screens.

## 5. Functional Requirements

- CART-FR-001: A user must be able to add an eligible product to the cart from an approved product screen.
- CART-FR-002: The application must provide visible feedback after an add-to-cart attempt.
- CART-FR-003: The cart must display all current cart items.
- CART-FR-004: A user must be able to increase or decrease an item quantity within approved limits.
- CART-FR-005: A user must be able to remove an item.
- CART-FR-006: Displayed totals must update after cart contents change.
- CART-FR-007: An empty cart must show a clear empty state and a path back to products.
- CART-FR-008: The checkout action must only be enabled when the cart satisfies the approved rules.

## 6. Business and Validation Rules

- Cart-item quantity must be a whole number of at least one.
- Cart-item quantity must not exceed the product's available stock quantity.
- Products with an available quantity of zero cannot be added to the cart.
- A user has one current cart and one line per product.
- Adding an existing product increases its quantity rather than creating another line.
- Cart prices and totals use current USD catalog prices and are recalculated after every mutation.
- Cart totals do not include the USD 4.00 delivery fee; it is added during checkout.
- The cart badge is the sum of item quantities, not the number of distinct lines.
- Guest carts and cart merging are deferred.

## 7. UI States

- Loading cart
- Cart with items
- Empty cart
- Updating item
- Removing item
- Update success
- Update failure
- Item unavailable or insufficient stock

## 8. Dependencies

- Product catalog
- Product pricing and stock rules
- Checkout
- Authentication

## 8.1 Backend implementation status

- All four `CRT` endpoints are implemented and require an access token.
- Reads return an empty cart without creating a database row.
- Mutations are owner-scoped, validate current product visibility and stock, and return the complete
  recalculated cart.
- Cart-item quantities, line totals, subtotals, and the profile cart counter are derived from current
  cart contents and catalog prices.
- The `V6__create_cart_and_wishlist.sql` migration is applied; wishlist APIs remain planned.

## 9. Acceptance Criteria

- Adding an eligible product produces clear feedback and updates the cart state.
- Quantity changes update the displayed item and totals.
- The cart prevents a quantity from exceeding available stock.
- Removing an item removes it from the displayed cart.
- An empty cart provides a route back to product discovery.
- Invalid or failed operations leave the cart in a clear, recoverable state.

## 10. Out of Scope

- Checkout form and order placement
- Guest carts, cart merging, discounts, tax, and inventory reservation
