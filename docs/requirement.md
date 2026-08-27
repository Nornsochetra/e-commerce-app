# Project Requirements

## 1. Project Overview

The project is a mobile e-commerce application that allows users to discover products, manage a cart
and wishlist, place and review orders, and receive shopping and order notifications.

This document records the current high-level requirements. Detailed behavior is maintained in the linked feature specifications.

## 2. Project Objectives

- Provide a modern, clean, and user-friendly mobile interface.
- Provide clear and smooth navigation between the application's screens.
- Support the primary customer journey from account access through product discovery and ordering.
- Contain at least 20 screens/pages when the complete project scope is delivered.

## 3. Project Scope

### 3.1 Current Scope

- User authentication and account registration
- User profile viewing and editing
- Product discovery, search, filtering, and details
- Shopping cart and wishlist management
- Checkout, order confirmation, order history, and order details
- In-app notifications for order and shopping updates

### 3.2 Deferred Scope

The following required features will be specified in a later phase:

- Settings
- About application
- Contact information

### 3.3 Out of Scope

No feature has been declared permanently out of scope yet.

## 4. User Roles

### 4.1 Guest

A user who has not authenticated. A guest can open authentication screens and browse/search/filter
the public catalog. Cart, wishlist, checkout, orders, profile, and notifications require sign-in.

### 4.2 Authenticated User

A registered and signed-in customer who can use all features in the current scope. All personal
resources are restricted to their owner.

## 5. Feature Requirements

Detailed requirements are maintained in the [features directory](features/README.md).

- [Authentication](features/authentication.md)
- [User profile](features/user-profile.md)
- [Product catalog](features/product-catalog.md)
- [Shopping cart](features/shopping-cart.md)
- [Wishlist](features/wishlist.md)
- [Orders and checkout](features/orders.md)
- [Notifications](features/notifications.md)

## 6. Screen Inventory

Actions such as adding an item, changing its quantity, and removing it from the cart are behaviors rather than separate screens.

| ID | Screen | Feature | Status |
|---|---|---|---|
| SCR-001 | Splash | Authentication | Current scope |
| SCR-002 | Login | Authentication | Current scope |
| SCR-003 | Register | Authentication | Current scope |
| SCR-004 | Forgot password | Authentication | Current scope |
| SCR-005 | User profile | User profile | Current scope |
| SCR-006 | Edit profile | User profile | Current scope |
| SCR-007 | Home | Product catalog | Current scope |
| SCR-008 | Product categories | Product catalog | Current scope |
| SCR-009 | Product list | Product catalog | Current scope |
| SCR-010 | Product details | Product catalog | Current scope |
| SCR-011 | Search products | Product catalog | Current scope |
| SCR-012 | Product filtering | Product catalog | Current scope; bottom sheet |
| SCR-013 | Shopping cart | Shopping cart | Current scope |
| SCR-014 | Wishlist/favorites | Wishlist | Current scope |
| SCR-015 | Checkout | Orders | Current scope |
| SCR-016 | Order confirmation | Orders | Current scope |
| SCR-017 | Order history | Orders | Current scope |
| SCR-018 | Order details | Orders | Current scope |
| SCR-019 | Notifications | Notifications | Current scope |
| SCR-020 | Settings | Additional features | Deferred |
| SCR-021 | About application | Additional features | Deferred |
| SCR-022 | Contact information | Additional features | Deferred |

The current scope defines 19 screens. The three deferred screens bring the complete requirement to
22 screens, satisfying the minimum of 20.

## 7. System-wide business rules

### 7.1 Accounts and sessions

- Email and password are the v1 credentials.
- Email comparison is case-insensitive.
- Passwords contain at least 8 characters and are stored only as one-way hashes.
- Access tokens last 15 minutes; refresh tokens last 7 days. Refreshing issues a new pair without
  invalidating earlier unexpired pairs; logout invalidates all tokens for the account.
- Registration signs the user in immediately. Email verification is deferred.
- Password recovery accepts an email and always returns the same acknowledgement. Recovery delivery
  and reset completion remain deferred until an email provider is selected.

### 7.2 Shopping ownership

- Catalog browsing is public.
- Cart and wishlist require authentication in v1.
- Each user has one current cart and one wishlist collection.
- Guest persistence and guest-to-account merging are deferred.

### 7.3 Pricing and currency

- V1 uses USD.
- Product and cart prices use the current catalog price.
- The server calculates all totals; client totals are never trusted.
- Order items and order totals are stored as checkout-time snapshots.
- Discounts and tax are not applied in v1.

### 7.4 Stock

- Available quantity is a non-negative whole number.
- Cart quantity is at least one and cannot exceed currently available quantity.
- Cart validation is informational; order placement validates stock again and decrements it in the
  same transaction.
- Inventory reservation and back-ordering are deferred.

### 7.5 Checkout and orders

- Checkout requires an authenticated user and a non-empty valid cart.
- V1 delivery uses one recipient name, email, and free-form address.
- Standard delivery is 2–4 business days with a flat USD 4.00 fee.
- Cash on delivery is the only production v1 payment method. Card remains prototype-only.
- Order creation requires an idempotency key to prevent duplicates.
- The v1 status flow is `pending → confirmed → shipped → delivered`.
- Cancellation, returns, refunds, and user-driven status changes are deferred.

### 7.6 Notifications

- Notifications belong to one authenticated user.
- A notification may be read, marked read, or cleared from the user's inbox.
- V1 notification types are `order`, `offer`, and `stock`.
- Push delivery and notification preferences are deferred; v1 is an in-app inbox.

## 8. Non-Functional Requirements

### 8.1 Usability

- The interface must be modern, clean, and user-friendly.
- Navigation labels and controls must be clear and consistent.
- Important actions must provide visible feedback.
- Loading, empty, success, validation, and error states must be represented where applicable.

### 8.2 Responsive layout

- Flutter screens target Android and iOS phones in portrait orientation.
- Layouts support widths from 360 logical pixels upward without clipped primary actions.

### 8.3 Accessibility

- Interactive controls must expose semantic labels and support screen readers.
- Text and controls must meet WCAG 2.1 AA contrast targets.
- Touch targets must be at least 44 × 44 logical pixels where platform controls allow it.

### 8.4 Performance and security

- Product and order list endpoints are paginated and cap page size at 100.
- Secrets and credentials must not appear in source control, logs, or API responses.
- Personal resources must be queried using the authenticated owner scope.
- Loading and mutation actions must prevent accidental duplicate submission.

## 9. Assumptions and Constraints

- The current requirements describe a customer-facing mobile application.
- The prototype will use mock data and will not provide real authentication, payment, or order processing.
- Settings, about, contact, card processing, push notifications, email delivery, guest shopping,
  cancellation, returns, tax, and discounts are deferred from v1.

## 10. System-Wide Acceptance Criteria

- All approved screens can be reached through a clear navigation path.
- Each approved feature includes its required normal, loading, empty, and error states where applicable.
- The final application contains at least 20 distinct screens/pages.
- Feature behavior matches the approved feature specifications.
- The primary journey works end to end: register/login → browse → cart → checkout → confirmation →
  order history/details.
- An authenticated user can review, mark, and clear in-app notifications.
