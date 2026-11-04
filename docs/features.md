# Features

Detailed requirements for the APM (All Products Marketplace) v1 customer experience.

| Feature | Section | Status |
|---|---|---|
| Authentication | [Go to section](#authentication) | Approved for v1 |
| User profile | [Go to section](#user-profile) | Approved for v1 |
| Product catalog | [Go to section](#product-catalog) | Approved for v1 |
| Shopping cart | [Go to section](#shopping-cart) | Approved for v1 |
| Wishlist | [Go to section](#wishlist) | Approved for v1 |
| Orders and checkout | [Go to section](#orders-and-checkout) | Approved for v1 |
| Notifications | [Go to section](#notifications) | Approved for v1 |

Settings, About application, and Contact information remain deferred.

Cross-cutting behavior is defined in:

- [Project requirements](requirements.md#project-requirements)
- [Use cases](requirements.md#use-cases)
- [API conventions](api.md#api-conventions)
- [API specification](api.md#api-specification)
- [Data model](database.md)

## Authentication

### 1. Overview

Authentication provides the initial application entry and the flows required for a user to access or create an account and recover access to an existing account.

### 2. Goals

- Introduce the application through a splash screen.
- Allow an existing user to log in.
- Allow a new user to register.
- Provide clear validation, loading, success, and failure feedback.

### 3. Actors

- Guest
- Registered user who is not currently authenticated

### 4. Screens

#### 4.1 Splash

- Display the application identity while initialization takes place.
- Continue to the appropriate next screen after initialization.
- Restore a valid refresh token and open Home; otherwise open Login.

#### 4.2 Login

- Display the credentials required to log in.
- Submit valid credentials.
- Provide navigation to registration and forgot-password flows.
- Use case-insensitive email and password credentials.

#### 4.3 Register

- Display the fields required to create an account.
- Validate the provided information before submission.
- Require name, email, password, and matching password confirmation. Registration signs the user in;
  email verification and consent capture are deferred.

#### 4.4 Forgot Password (removed)

The app has no forgot-password screen. Signed-in users change their password from Profile (see
[Go to section](#user-profile)). The backend still accepts `AUT-0204`, but the app does not call it.

### 5. Primary User Flows

#### 5.1 Application Entry

1. The user opens the application.
2. The splash screen is displayed.
3. The application completes its initialization checks.
4. The user is routed according to the approved session rules.

#### 5.2 Login

1. The user opens the login screen.
2. The user enters the required credentials.
3. The application validates the input.
4. The application displays a loading state during submission.
5. On success, the user is sent to the approved destination.
6. On failure, the application displays an actionable error message.

#### 5.3 Registration

1. The user opens the registration screen.
2. The user completes the required fields.
3. The application validates the input.
4. The user submits the form.
5. The application displays the appropriate success or error state.

### 6. Functional Requirements

- AUTH-FR-001: The application must display a splash screen when launched.
- AUTH-FR-002: The application must provide navigation from login to registration.
- AUTH-FR-003: Removed (login no longer links to forgot password).
- AUTH-FR-004: The application must prevent submission when required visible fields are invalid.
- AUTH-FR-005: The application must show submission progress.
- AUTH-FR-006: The application must show understandable success and error feedback.
- AUTH-FR-007: The application must prevent duplicate submissions while a request is in progress.

### 7. Business and Validation Rules

- Email comparison is case-insensitive and stored email is trimmed.
- Passwords contain at least 8 characters and are never logged or returned.
- Registration rejects a normalized email already in use and signs the new user in immediately.
- Access tokens expire after 15 minutes.
- Refresh tokens expire after 7 days. Refreshing issues a new token pair, while previously issued
  refresh tokens remain valid until their own expiration or logout.
- Logout requires only the access token, increments the account token version, and invalidates all
  access and refresh tokens previously issued to that account on every device. The client also
  discards its locally stored tokens.
- A refresh token cannot authorize a normal API request.
- Login uses one `INVALID_CREDENTIALS` result for wrong email or password.
- Recovery requests do not reveal whether an account exists.

### 8. UI States

- Initial
- Input focused
- Invalid input
- Submitting/loading
- Submission success
- Submission failure
- Offline or unavailable service

### 9. Security Requirements

- Passwords are stored only as adaptive one-way hashes with a work factor of at least 10.
- Access and refresh tokens are stored using the platform's secure credential storage in production.
- Raw passwords, token values, and password hashes must not appear in application logs.
- HTTPS is required outside local development.

### 10. Dependencies

- Authentication API specification
- Session and authorization conventions
- Approved navigation flow

### 11. Acceptance Criteria

- All four authentication screens are reachable through the defined navigation flow.
- Forms communicate required fields and validation errors clearly.
- A submission displays progress and cannot be triggered repeatedly while loading.
- Success and failure outcomes are visually distinct.
- Splash opens Home for a restored valid session and Login otherwise.

### 12. Out of Scope

- User profile management
- Product browsing
- Shopping and ordering
- Email verification, social login, multi-factor authentication, and password reset for signed-out users

## User profile

### 1. Overview

The user-profile feature allows an authenticated user to view and update approved account information.

### 2. Goals

- Present the user's account information clearly.
- Allow editable information to be changed through a dedicated flow.
- Communicate validation and update results.

### 3. Actor

- Authenticated user

### 4. Screens

#### 4.1 User Profile

- Display the approved profile fields.
- Provide navigation to edit the profile.
- Provide navigation to orders, wishlist, cart, and sign out.

#### 4.2 Edit Profile

- Display editable profile fields.
- Validate changes before submission.
- Allow the user to save or cancel changes.
- Editable fields are name, email, and optional phone. Avatar support is deferred.

#### 4.3 Change Password

- Opened from the Profile menu, below My orders, as a popup.
- Fields: current password, new password (8–72 characters, different from the current one), and
  confirmation.
- A wrong current password is shown on that field (`CURRENT_PASSWORD_INCORRECT`).
- Success keeps this device signed in with a new token pair, signs out every other device, and shows
  "Password changed". Closing with something typed asks before discarding it.

### 5. Functional Requirements

- PROFILE-FR-001: The application must display the current user's approved profile information.
- PROFILE-FR-002: The application must provide a clear edit action.
- PROFILE-FR-003: The user must be able to cancel editing without saving changes.
- PROFILE-FR-004: Invalid fields must be identified before submission.
- PROFILE-FR-005: Saving must display loading, success, and failure feedback.
- PROFILE-FR-006: The profile screen must reflect successfully saved changes.

### 6. Business and Validation Rules

- Name is required, trimmed, and limited to 100 characters.
- Email is required, trimmed, validated, and unique case-insensitively.
- Phone is optional, may be cleared, and is limited to 32 characters; international normalization is
  deferred.
- Changing profile fields does not require re-authentication in v1.
- Password and role are not profile fields; the password changes only through Change password.

### 7. UI States

- Loading profile
- Profile loaded
- Profile unavailable
- Editing
- Invalid changes
- Saving
- Save success
- Save failure

### 8. Dependencies

- Authentication
- Final user data model
- User-profile API specification

### 8.1 Backend implementation status

- `GET /api/v1/auth/me` is the single current-user information endpoint.
- `PATCH /api/v1/me/profile` updates approved profile fields.
- Reads and updates are authenticated and scoped to the access-token owner.
- Email uniqueness is enforced case-insensitively; email is normalized to lowercase.
- Order, wishlist, and cart counters return zero until their corresponding backend sections are
  implemented.

### 9. Acceptance Criteria

- An authenticated user can reach the profile and edit-profile screens.
- Current approved profile information is visible.
- Canceling an edit does not apply changes.
- Successful changes appear on the profile screen.
- Validation and request failures provide understandable feedback.

### 10. Out of Scope

- Authentication flows
- Settings, avatar upload, and account deletion

## Product catalog

### 1. Overview

The product-catalog feature enables users to discover products from the home screen, browse categories and lists, inspect product details, search, and filter results.

### 2. Goals

- Make product discovery simple and visually clear.
- Allow browsing by category.
- Support product search and filtering.
- Present enough product information for a user to make a shopping decision.

### 3. Actors

- Guest
- Authenticated user

Guests and authenticated users have the same read-only catalog access. Shopping actions require
authentication.

### 4. Screens

#### 4.1 Home

- Present navigation and approved product-discovery sections.
- Display the current featured collection, category shortcuts, and popular products.

#### 4.2 Product Categories

- Display available categories.
- Open the relevant product list when a category is selected.

#### 4.3 Product List

- Display product summaries in the approved layout.
- Support navigation to product details.
- Represent loading, empty, error, and loaded results.

#### 4.4 Product Details

- Display approved product information and available shopping actions.
- Display the product's available stock quantity.
- Display the description when one is provided; omit the description section when it is absent.
- Allow the user to select a purchase quantity, starting at one and not exceeding the available stock quantity.
- Product variants are deferred. An absent image uses the approved application placeholder.

##### Product Content

| Field | Required | Notes |
|---|---|---|
| Name | Yes | Display name of the product |
| Price | Yes | Current product price |
| Description | No | Optional descriptive content; the UI must handle a missing value cleanly |
| Quantity | Yes | Available stock quantity represented by a non-negative whole number |
| Image | No | Absolute image URL; use the application placeholder when absent |
| Category | Yes | One active flat category in v1 |

#### 4.5 Search Products

- Allow entry and submission of a search query.
- Display matching products or a no-results state.
- Search suggestions and history are TBD.

#### 4.6 Product Filtering

- Allow users to apply and clear approved filters.
- Display active filters and update the result set.
- Filtering is presented as a bottom sheet on mobile.

### 5. Functional Requirements

- PRODUCT-FR-001: Users must be able to navigate from home to product discovery screens.
- PRODUCT-FR-002: Users must be able to browse products by category.
- PRODUCT-FR-003: Selecting a product must open its details.
- PRODUCT-FR-004: Users must be able to submit a product search.
- PRODUCT-FR-005: Users must receive clear feedback when no search results exist.
- PRODUCT-FR-006: Users must be able to apply and clear approved filters.
- PRODUCT-FR-007: Product collections must represent loading, empty, loaded, and error states.
- PRODUCT-FR-008: Product details must display the available stock quantity.
- PRODUCT-FR-009: A missing optional description must not leave an empty or broken UI section.
- PRODUCT-FR-010: The selected purchase quantity must not exceed the available stock quantity.

### 6. Business and Validation Rules

- A product description is optional.
- Available quantity must be a non-negative whole number.
- A quantity of zero represents an out-of-stock product.
- The selected purchase quantity must be at least one and must not exceed available quantity.
- Only active products in active categories are visible.
- V1 prices are USD current catalog prices.
- Search is a case-insensitive product-name contains match.
- Filters are category and in-stock availability.
- Supported sorts are featured (default), price ascending, price descending, rating descending,
  name ascending, and newest.
- Product lists are zero-based pages with default size 20 and maximum size 100.

### 7. UI States

- Loading
- Loaded
- Empty catalog
- No search results
- Error
- Filters inactive
- Filters active
- Product unavailable

### 8. Dependencies

- Product and category data models
- Product API specification
- Shopping cart
- Wishlist

### 8.1 Backend implementation status

- Active categories, product search/filtering, and product details are implemented.
- Catalog reads are public and expose only active products in active categories.
- Pagination, approved sorts, stock filtering, descriptions, ratings, images, and badges follow the
  API contract.
- The `V5__create_catalog.sql` migration is applied.

### 9. Acceptance Criteria

- All six product-related screens or approved presentations are reachable.
- Users can move from a category or result list to product details.
- Search and filtering visibly affect the displayed results.
- Users can clear active search/filter criteria.
- Loading, empty, unavailable, and failure cases have clear UI states.
- A product without a description is displayed without an empty description section.
- Available stock and the permitted purchase quantity are represented correctly.

### 10. Out of Scope

- Product administration
- Product variants, product administration, recommendations, search history, and review submission
- Real inventory updates in the prototype

## Shopping cart

### 1. Overview

The shopping-cart feature allows users to collect products intended for purchase, change quantities, remove items, and continue toward checkout.

### 2. Goals

- Make cart contents and totals easy to understand.
- Allow quantities to be changed safely.
- Allow unwanted items to be removed.
- Provide a clear transition to checkout.

### 3. Actor

- Authenticated user

### 4. Screen

#### 4.1 Shopping Cart

- Display cart items and their approved summary information.
- Display quantity controls and removal actions.
- Display approved totals.
- Provide navigation to checkout when the cart is eligible.

Adding an item, updating quantity, and removing an item are interactions rather than separate screens.

### 5. Functional Requirements

- CART-FR-001: A user must be able to add an eligible product to the cart from an approved product screen.
- CART-FR-002: The application must provide visible feedback after an add-to-cart attempt.
- CART-FR-003: The cart must display all current cart items.
- CART-FR-004: A user must be able to increase or decrease an item quantity within approved limits.
- CART-FR-005: A user must be able to remove an item.
- CART-FR-006: Displayed totals must update after cart contents change.
- CART-FR-007: An empty cart must show a clear empty state and a path back to products.
- CART-FR-008: The checkout action must only be enabled when the cart satisfies the approved rules.

### 6. Business and Validation Rules

- Cart-item quantity must be a whole number of at least one.
- Cart-item quantity must not exceed the product's available stock quantity.
- Products with an available quantity of zero cannot be added to the cart.
- A user has one current cart and one line per product.
- Adding an existing product increases its quantity rather than creating another line.
- Cart prices and totals use current USD catalog prices and are recalculated after every mutation.
- Cart totals do not include the USD 4.00 delivery fee; it is added during checkout.
- The cart badge is the sum of item quantities, not the number of distinct lines.
- Guest carts and cart merging are deferred.

### 7. UI States

- Loading cart
- Cart with items
- Empty cart
- Updating item
- Removing item
- Update success
- Update failure
- Item unavailable or insufficient stock

### 8. Dependencies

- Product catalog
- Product pricing and stock rules
- Checkout
- Authentication

### 8.1 Backend implementation status

- All four `CRT` endpoints are implemented and require an access token.
- Reads return an empty cart without creating a database row.
- Mutations are owner-scoped, validate current product visibility and stock, and return the complete
  recalculated cart.
- Cart-item quantities, line totals, subtotals, and the profile cart counter are derived from current
  cart contents and catalog prices.
- The `V6__create_cart_and_wishlist.sql` migration is applied; wishlist APIs remain planned.

### 9. Acceptance Criteria

- Adding an eligible product produces clear feedback and updates the cart state.
- Quantity changes update the displayed item and totals.
- The cart prevents a quantity from exceeding available stock.
- Removing an item removes it from the displayed cart.
- An empty cart provides a route back to product discovery.
- Invalid or failed operations leave the cart in a clear, recoverable state.

### 10. Out of Scope

- Checkout form and order placement
- Guest carts, cart merging, discounts, tax, and inventory reservation

## Wishlist

### 1. Overview

The wishlist feature allows users to mark products as favorites and review those products in one place.

### 2. Goals

- Allow products to be saved or unsaved with clear feedback.
- Present saved products in a dedicated screen.
- Provide a route from a saved product to its details.

### 3. Actor

- Authenticated user

### 4. Screen

#### 4.1 Wishlist/Favorite Products

- Display saved products.
- Allow a saved product to be opened.
- Allow a saved product to be removed.
- Display an informative empty state.

### 5. Functional Requirements

- WISHLIST-FR-001: A user must be able to mark an eligible product as a favorite from approved product screens.
- WISHLIST-FR-002: The selected favorite state must be visible.
- WISHLIST-FR-003: A user must be able to view saved products on the wishlist screen.
- WISHLIST-FR-004: A user must be able to remove a saved product.
- WISHLIST-FR-005: Selecting a saved product must open its product details.
- WISHLIST-FR-006: An empty wishlist must provide a route to product discovery.

### 6. Business and Validation Rules

- A wishlist belongs to one authenticated user and persists across sessions.
- A product can appear only once; saving it again is idempotent.
- Saved items are displayed newest first.
- An unavailable product remains visible with its current availability and cannot be added to cart.
- V1 has no explicit wishlist limit.

### 7. UI States

- Loading
- Wishlist with products
- Empty wishlist
- Saving or removing favorite
- Operation failure
- Saved product unavailable

### 8. Dependencies

- Product catalog
- Authentication
- Wishlist API specification

### 8.1 Backend implementation status

- All three `WSH` endpoints are implemented and require an access token.
- Wishlist reads are owner-scoped, paginated, and ordered by newest saved item with a stable id
  tie-breaker.
- Saving an active visible product returns 201 when new and 200 when already saved.
- Previously saved unavailable products remain visible with current catalog values.
- The profile wishlist counter is derived from the current user's saved products.
- Persistence uses the `wishlist_items` table already applied in `V6__create_cart_and_wishlist.sql`.

### 9. Acceptance Criteria

- Favorite controls visibly reflect the current mock state.
- Saved products appear on the wishlist screen.
- Removing a favorite updates the wishlist.
- A user can navigate from a saved product to its details.
- Empty and failure states provide clear feedback.

### 10. Out of Scope

- Sharing wishlists
- Multiple named wishlists
- Guest wishlists, sharing, and multiple named wishlists

## Orders and checkout

### 1. Overview

The orders feature supports the customer journey from reviewing checkout information through confirmation and later review of order history and details.

### 2. Goals

- Present a clear checkout summary.
- Collect or select all information required to place an order.
- Confirm the result of an order attempt.
- Allow users to review previous orders and their details.

### 3. Actor

- Authenticated user

### 4. Screens

#### 4.1 Checkout

- Display the order summary and required checkout information.
- Validate required information before order submission.
- Collect recipient name, delivery email, and free-form delivery address.
- Use standard delivery (2–4 business days) for USD 4.00.
- Cash on delivery is the v1 production payment method. Card remains prototype-only.

#### 4.2 Order Confirmation

- Clearly communicate successful order creation.
- Display the approved confirmation summary and next actions.

#### 4.3 Order History

- Display the user's orders in the approved order.
- Provide navigation to order details.
- Display loading, empty, and failure states.

#### 4.4 Order Details

- Display the approved order, item, pricing, delivery, payment, and status information.
- V1 order details are read-only.

### 5. Primary User Flows

#### 5.1 Checkout and Confirmation

1. The user proceeds from an eligible cart to checkout.
2. The user reviews the order and supplies or selects required information.
3. The application validates the checkout information.
4. The user submits the order once.
5. The application displays progress during submission.
6. On success, the order confirmation screen is displayed.
7. On failure, the checkout screen preserves recoverable information and displays an actionable error.

#### 5.2 Review an Existing Order

1. The user opens order history.
2. The application displays current orders or the appropriate empty/error state.
3. The user selects an order.
4. The application displays that order's details.

### 6. Functional Requirements

- ORDER-FR-001: An eligible cart must be able to proceed to checkout.
- ORDER-FR-002: Checkout must display an order summary before submission.
- ORDER-FR-003: Required checkout information must be validated.
- ORDER-FR-004: Repeated submission must be prevented while order creation is in progress.
- ORDER-FR-005: Successful creation must open an order confirmation screen.
- ORDER-FR-006: Failed creation must provide a recoverable error state.
- ORDER-FR-007: A user must be able to view order history.
- ORDER-FR-008: Selecting an order must open its details.

### 7. Business and Validation Rules

- Checkout requires a non-empty cart whose quantities do not exceed current stock.
- The server recalculates product prices, subtotal, delivery fee, and total.
- V1 currency is USD; discounts and tax are not applied.
- Order creation uses an idempotency key and cannot create a duplicate on retry.
- Stock is revalidated and decremented in the same transaction as order creation.
- Order items store product name, image, quantity, price, and currency snapshots.
- Status progresses forward through `pending → confirmed → shipped → delivered`.
- Card payment, cancellation, returns, and refunds are deferred.

### 8. UI States

- Loading checkout
- Checkout ready
- Invalid checkout information
- Submitting order
- Order success
- Order failure
- Loading history/details
- Empty history
- History/details failure

### 9. Dependencies

- Authentication
- Shopping cart
- Product pricing and stock rules
- User profile data
- Order API specification

### 9.1 Backend implementation status

- Checkout preview, order placement, history, and detail endpoints are implemented and authenticated.
- Placement locks stock in stable product-id order, revalidates availability, stores immutable item
  and delivery snapshots, decrements inventory, and clears the cart in one transaction.
- `Idempotency-Key` replay returns the original order for compatible input and `CONFLICT` for changed
  checkout input.
- History is owner-scoped, newest-first, paginated, and optionally filtered by order status.
- A newly placed order creates one unread order notification in the same transaction; an
  idempotency replay does not create another notification.
- The profile order counter is derived from placed orders.
- The `V7__create_orders.sql` migration is applied.

### 10. Acceptance Criteria

- The user can navigate from an eligible cart to checkout.
- Required checkout information is validated before submission.
- Order submission provides progress and prevents duplicate attempts.
- A successful mock submission opens order confirmation.
- Order history supports loaded, empty, and failure states.
- Selecting an order opens the corresponding details.

### 11. Out of Scope

- Card-payment provider integration
- Order cancellation, returns, refunds, tax, and discounts

## Notifications

### 1. Overview

Notifications provide an authenticated user with an in-app inbox for order and shopping updates.

### 2. Goals

- Make unread updates visible from the catalog header.
- Let users review all or only unread notifications.
- Let users mark one or all notifications as read.
- Let users clear their notification inbox.

### 3. Actor

- Authenticated user

### 4. Screen

#### 4.1 Notifications

- Display unread count in the header.
- Display notifications newest first.
- Support All and Unread filters.
- Visually distinguish unread notifications.
- Support mark-read, mark-all-read, and clear-all actions.
- Display an informative empty state.

### 5. Functional requirements

- NOTIFICATION-FR-001: The catalog header must show a notification indicator when unread items exist.
- NOTIFICATION-FR-002: Selecting the indicator must open the notifications screen.
- NOTIFICATION-FR-003: A user must see only their own notifications.
- NOTIFICATION-FR-004: Notifications must be ordered newest first.
- NOTIFICATION-FR-005: A user must be able to filter the list to unread notifications.
- NOTIFICATION-FR-006: A user must be able to mark one notification as read.
- NOTIFICATION-FR-007: A user must be able to mark all notifications as read.
- NOTIFICATION-FR-008: A user must be able to clear all notifications from their inbox.
- NOTIFICATION-FR-009: The screen must provide loading, empty, loaded, and failure states.

### 6. Business rules

- Notifications require authentication and are owner-scoped.
- V1 types are `order`, `offer`, and `stock`.
- Notification title and message are immutable after creation.
- Reading records `read_at`; an unread notification has `read_at = null`.
- Clearing removes the notification from the user's inbox through soft state; it does not erase the
  server record immediately.
- The unread count includes visible, uncleared notifications only.
- Push notifications, email notifications, preferences, and deep-link actions are deferred.

### 7. UI states

- Loading
- Loaded with unread notifications
- Loaded with all notifications read
- Unread filter with no results
- Empty inbox
- Mark-read operation failure
- Clear-all operation failure

### 8. Dependencies

- Authentication
- Orders for order updates
- Product catalog for stock and offer updates
- Notification API specification

### 8.1 Backend implementation status

- The inbox, unread-count, mark-read, mark-all-read, and clear-all endpoints are implemented and
  authenticated.
- All reads and mutations are owner-scoped; missing, cleared, and other-user notification IDs share
  the `NOTIFICATION_NOT_FOUND` response.
- Read and bulk operations are idempotent, while clear-all records `cleared_at` without deleting
  notification history.
- Lists are newest-first, paginated, and support the approved `all` and `unread` filters.
- A successful new order creates one unread order notification in the checkout transaction;
  idempotency replay does not create a duplicate.
- The `V8__create_notifications.sql` migration is applied.

### 9. Acceptance criteria

- The notification indicator opens the inbox.
- Unread count and unread styling agree with notification state.
- Marking one or all as read updates the count immediately.
- Clearing the inbox displays the empty state.
- Refreshing restores the latest server state in production and local mock state in the prototype.
- One user cannot read or mutate another user's notifications.

### 10. Out of scope

- Push delivery
- Email or SMS delivery
- Notification preferences
- Scheduled campaigns
- Deep linking to feature screens
