# Orders and Checkout

## 1. Overview

The orders feature supports the customer journey from reviewing checkout information through confirmation and later review of order history and details.

## 2. Goals

- Present a clear checkout summary.
- Collect or select all information required to place an order.
- Confirm the result of an order attempt.
- Allow users to review previous orders and their details.

## 3. Actor

- Authenticated user

## 4. Screens

### 4.1 Checkout

- Display the order summary and required checkout information.
- Validate required information before order submission.
- Collect recipient name, delivery email, and free-form delivery address.
- Use standard delivery (2–4 business days) for USD 4.00.
- Cash on delivery is the v1 production payment method. Card remains prototype-only.

### 4.2 Order Confirmation

- Clearly communicate successful order creation.
- Display the approved confirmation summary and next actions.

### 4.3 Order History

- Display the user's orders in the approved order.
- Provide navigation to order details.
- Display loading, empty, and failure states.

### 4.4 Order Details

- Display the approved order, item, pricing, delivery, payment, and status information.
- V1 order details are read-only.

## 5. Primary User Flows

### 5.1 Checkout and Confirmation

1. The user proceeds from an eligible cart to checkout.
2. The user reviews the order and supplies or selects required information.
3. The application validates the checkout information.
4. The user submits the order once.
5. The application displays progress during submission.
6. On success, the order confirmation screen is displayed.
7. On failure, the checkout screen preserves recoverable information and displays an actionable error.

### 5.2 Review an Existing Order

1. The user opens order history.
2. The application displays current orders or the appropriate empty/error state.
3. The user selects an order.
4. The application displays that order's details.

## 6. Functional Requirements

- ORDER-FR-001: An eligible cart must be able to proceed to checkout.
- ORDER-FR-002: Checkout must display an order summary before submission.
- ORDER-FR-003: Required checkout information must be validated.
- ORDER-FR-004: Repeated submission must be prevented while order creation is in progress.
- ORDER-FR-005: Successful creation must open an order confirmation screen.
- ORDER-FR-006: Failed creation must provide a recoverable error state.
- ORDER-FR-007: A user must be able to view order history.
- ORDER-FR-008: Selecting an order must open its details.

## 7. Business and Validation Rules

- Checkout requires a non-empty cart whose quantities do not exceed current stock.
- The server recalculates product prices, subtotal, delivery fee, and total.
- V1 currency is USD; discounts and tax are not applied.
- Order creation uses an idempotency key and cannot create a duplicate on retry.
- Stock is revalidated and decremented in the same transaction as order creation.
- Order items store product name, image, quantity, price, and currency snapshots.
- Status progresses forward through `pending → confirmed → shipped → delivered`.
- Card payment, cancellation, returns, and refunds are deferred.

## 8. UI States

- Loading checkout
- Checkout ready
- Invalid checkout information
- Submitting order
- Order success
- Order failure
- Loading history/details
- Empty history
- History/details failure

## 9. Dependencies

- Authentication
- Shopping cart
- Product pricing and stock rules
- User profile data
- Order API specification

## 10. Acceptance Criteria

- The user can navigate from an eligible cart to checkout.
- Required checkout information is validated before submission.
- Order submission provides progress and prevents duplicate attempts.
- A successful mock submission opens order confirmation.
- Order history supports loaded, empty, and failure states.
- Selecting an order opens the corresponding details.

## 11. Out of Scope

- Card-payment provider integration
- Order cancellation, returns, refunds, tax, and discounts
