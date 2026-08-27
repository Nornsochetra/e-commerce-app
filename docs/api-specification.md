---
spec: SPEC-API
title: API Specification
status: draft
owner: Backend
depends_on: [SPEC-API-CONVENTIONS, SPEC-DATA-MODEL]
last_updated: 2026-08-27
---

# API specification

Endpoint contracts for the current e-commerce scope. Cross-cutting behavior—response envelopes,
errors, authentication, enum spelling, pagination, money, and timestamps—is defined in
[API conventions](api-convention.md). Database fields and ownership rules are defined in
[Data model](data-model.md).

> **Implementation boundary:** The backend currently implements `GET /health`, the complete `AUT`
> authentication area, and shared envelope/security behavior. Every endpoint in the other feature
> areas remains planned until its controller exists. “Approved” does not mean “implemented.”

Every path is relative to `/api/v1`. Every endpoint has a stable `<AREA>-<NNNN>` ApiId.

## 1. Envelope examples

Success (`error` absent):

```json
{
  "status": { "code": "SUCCESS", "message": "Success" },
  "data": {},
  "common": {
    "requestId": "0f2c9e14-6b8a-4d31-9f77-2c1e5a90b4d3",
    "apiId": "CAT-0601",
    "timestamp": "2026-08-24T04:12:00Z"
  }
}
```

Failure (`data` absent):

```json
{
  "status": { "code": "PRODUCT_NOT_FOUND", "message": "Product was not found" },
  "common": { "requestId": "0f2c…", "apiId": "CAT-0601", "timestamp": "2026-08-24T04:12:00Z" },
  "error": { "code": "PRODUCT_NOT_FOUND", "type": "NOT_FOUND", "message": "Product was not found" }
}
```

## 2. Feature areas

| Area | Feature | Client surface | Contract status |
|---|---|---|---|
| `HLT` | Service health | Infrastructure | Implemented |
| `AUT` | Login, registration, recovery, token lifecycle | Splash and authentication | Implemented |
| `USR` | Current-user profile | Profile and edit profile | Planned; contract approved |
| `CAT` | Categories, products, search, filters | Home and catalog | Planned; contract approved |
| `CRT` | Current cart and items | Shopping cart | Planned; contract approved |
| `WSH` | Current wishlist | Wishlist | Planned; contract approved |
| `ORD` | Checkout and order history | Checkout, confirmation, orders | Planned; contract approved |
| `NTF` | In-app notification inbox | Notifications and unread badge | Planned; contract approved |

The current security allow-list exposes health, auth entry routes, and development OpenAPI routes.
When the catalog slice is implemented, categories and product reads also become public. Cart,
wishlist, checkout, orders, profile, logout, and notifications remain authenticated and owner-scoped.

## 3. Endpoint inventory

### 3.1 `HLT` — health

| ApiId | Endpoint | Auth | Purpose |
|---|---|---|---|
| `HLT-0601` | `GET /health` | Public | Read service availability. |

Implemented response data:

```json
{
  "status": { "code": "SUCCESS", "message": "Success" },
  "data": { "status": "UP", "service": "ecommerce-api" },
  "common": {
    "requestId": "0f2c9e14-6b8a-4d31-9f77-2c1e5a90b4d3",
    "apiId": "HLT-0601",
    "timestamp": "2026-08-27T04:12:00Z"
  }
}
```

### 3.2 `AUT` — authentication

| ApiId | Endpoint | Auth | Purpose |
|---|---|---|---|
| `AUT-0201` | `POST /auth/login` | Public | Exchange email/password for tokens and user. |
| `AUT-0202` | `POST /auth/register` | Public | Create an account. |
| `AUT-0203` | `POST /auth/refresh` | Refresh token | Issue a new token pair. |
| `AUT-0204` | `POST /auth/forgot-password` | Public | Begin account recovery without revealing account existence. |
| `AUT-0205` | `POST /auth/logout` | Access token | Revoke all tokens for the current account. |
| `AUT-0601` | `GET /auth/me` | Access token | Read the authenticated identity. |

Verification and completion of password reset are intentionally absent until the recovery delivery
method is approved in [authentication.md](features/authentication.md).

### 3.3 `USR` — profile

| ApiId | Endpoint | Auth | Purpose |
|---|---|---|---|
| `USR-0601` | `GET /me/profile` | Required | Read the current profile. |
| `USR-0401` | `PATCH /me/profile` | Required | Partially update approved profile fields. |

### 3.4 `CAT` — product catalog

| ApiId | Endpoint | Auth | Purpose |
|---|---|---|---|
| `CAT-0101` | `GET /categories` | Public | List active categories. |
| `CAT-0102` | `GET /products` | Public | Search/filter products, paginated. |
| `CAT-0601` | `GET /products/{productId}` | Public | Read one visible product. |

`GET /products` accepts `page`, `size`, `sort`, `query`, `categoryId`, and `inStock`. Supported sorts
match the prototype: `featured,asc` (default), `price,asc`, `price,desc`, and `rating,desc`. The API
also accepts `name,asc` and `createdAt,desc`. Every sort adds `id,asc` or `id,desc` as a stable
tie-breaker.

### 3.5 `CRT` — shopping cart

| ApiId | Endpoint | Auth | Purpose |
|---|---|---|---|
| `CRT-0601` | `GET /cart` | Required | Read the current cart and derived totals. |
| `CRT-0201` | `POST /cart/items` | Required | Add a product or increase its existing quantity. |
| `CRT-0401` | `PATCH /cart/items/{itemId}` | Required | Set one item’s quantity. |
| `CRT-0501` | `DELETE /cart/items/{itemId}` | Required | Remove one item. |

### 3.6 `WSH` — wishlist

| ApiId | Endpoint | Auth | Purpose |
|---|---|---|---|
| `WSH-0101` | `GET /wishlist/items` | Required | List saved products. |
| `WSH-0201` | `POST /wishlist/items` | Required | Save a product; repeated save is idempotent. |
| `WSH-0501` | `DELETE /wishlist/items/{productId}` | Required | Remove a saved product. |

### 3.7 `ORD` — checkout and orders

| ApiId | Endpoint | Auth | Purpose |
|---|---|---|---|
| `ORD-0201` | `POST /orders/preview` | Required | Validate the cart and calculate a checkout preview. |
| `ORD-0202` | `POST /orders` | Required | Place an order from the current cart. |
| `ORD-0101` | `GET /orders` | Required | List the caller’s orders, paginated. |
| `ORD-0601` | `GET /orders/{orderId}` | Required | Read one caller-owned order and its items. |

Order cancellation, returns, refunds, card processing, and payment callbacks are deferred from v1 as
defined in [orders.md](features/orders.md).

### 3.8 `NTF` — notifications

| ApiId | Endpoint | Auth | Purpose |
|---|---|---|---|
| `NTF-0101` | `GET /notifications` | Required | List the caller's visible notifications, paginated. |
| `NTF-0601` | `GET /notifications/unread-count` | Required | Read the caller's unread count. |
| `NTF-0201` | `POST /notifications/{notificationId}/read` | Required | Mark one notification as read. |
| `NTF-0202` | `POST /notifications/read-all` | Required | Mark all visible notifications as read. |
| `NTF-0501` | `DELETE /notifications` | Required | Clear the caller's inbox using soft state. |

`GET /notifications` accepts `page`, `size`, and `filter=all|unread`, and sorts by
`createdAt,desc,id,desc`.

## 4. Contracts

All v1 money examples and contracts use USD.

### Endpoint field matrix

This matrix defines the request and response data for every inventory endpoint. The detailed examples
below define shared shapes. Envelope `status` and `common` fields are omitted from the matrix.

| ApiId | Request/query fields | Success response `data` | Endpoint-specific errors |
|---|---|---|---|
| `HLT-0601` | None | `status`, `service` | None. |
| `AUT-0201` | `email`, `password` | Token pair plus `UserIdentity` | `INVALID_CREDENTIALS`, `ACCOUNT_DISABLED` |
| `AUT-0202` | `name`, `email`, `password` | Token pair plus `UserIdentity` | `EMAIL_ALREADY_REGISTERED` |
| `AUT-0203` | `refreshToken` | Rotated `accessToken`, `refreshToken`, `expiresIn` | `INVALID_REFRESH_TOKEN` |
| `AUT-0204` | `email` | Empty object | No account-existence error is exposed. |
| `AUT-0205` | `refreshToken` | Empty object | `INVALID_REFRESH_TOKEN` |
| `AUT-0601` | None | `UserIdentity` | `USER_NOT_FOUND` |
| `USR-0601` | None | `UserProfile` | `USER_NOT_FOUND` |
| `USR-0401` | Any of `name`, `email`, `phone` | Updated `UserProfile` | `EMAIL_ALREADY_REGISTERED` |
| `CAT-0101` | None | Array of `Category` | None. |
| `CAT-0102` | `page`, `size`, `sort`, `query`, `categoryId`, `inStock` | `Pagination<ProductSummary>` | `CATEGORY_NOT_FOUND` |
| `CAT-0601` | Path `productId` | `ProductDetail` | `PRODUCT_NOT_FOUND` |
| `CRT-0601` | None | `Cart` | None; an empty cart is returned. |
| `CRT-0201` | `productId`, `quantity` | Updated `Cart` | `PRODUCT_NOT_FOUND`, `PRODUCT_OUT_OF_STOCK`, `INSUFFICIENT_STOCK` |
| `CRT-0401` | Path `itemId`; body `quantity` | Updated `Cart` | `CART_ITEM_NOT_FOUND`, `PRODUCT_NOT_FOUND`, `PRODUCT_OUT_OF_STOCK`, `INSUFFICIENT_STOCK` |
| `CRT-0501` | Path `itemId` | Updated `Cart` | `CART_ITEM_NOT_FOUND` |
| `WSH-0101` | `page`, `size` | `Pagination<ProductSummary>` | None. |
| `WSH-0201` | `productId` | `ProductSummary` | `PRODUCT_NOT_FOUND` |
| `WSH-0501` | Path `productId` | Empty object | `WISHLIST_ITEM_NOT_FOUND` |
| `ORD-0201` | `delivery`, `deliveryMethod`, `paymentMethod` | `CheckoutPreview` | `CART_EMPTY`, `INSUFFICIENT_STOCK`, `CHECKOUT_INVALID` |
| `ORD-0202` | Same body as preview; `Idempotency-Key` header | `OrderDetail` | `CART_EMPTY`, `INSUFFICIENT_STOCK`, `CHECKOUT_INVALID`, `CONFLICT` |
| `ORD-0101` | `page`, `size`, optional `status` | `Pagination<OrderSummary>` | None. |
| `ORD-0601` | Path `orderId` | `OrderDetail` | `ORDER_NOT_FOUND` |
| `NTF-0101` | `page`, `size`, `filter=all\|unread` | `Pagination<Notification>` | None. |
| `NTF-0601` | None | `unreadCount` | None. |
| `NTF-0201` | Path `notificationId` | Updated `Notification` | `NOTIFICATION_NOT_FOUND` |
| `NTF-0202` | None | `updatedCount`, `unreadCount` | None. |
| `NTF-0501` | None | `clearedCount`, `unreadCount` | None. |

All request bodies reject unknown fields. `VALIDATION_ERROR` applies to malformed identifiers,
missing required fields, invalid formats, unsupported enum values, and out-of-range values.

### 4.1 `POST /auth/login` · `AUT-0201`

Returns 200, or `VALIDATION_ERROR`, `INVALID_CREDENTIALS`, `ACCOUNT_DISABLED`.

`V3__add_user_public_fields.sql` provides the implemented public user identity fields. JWT payloads
are not persisted; `V4__add_user_token_version.sql` provides account-wide logout revocation.

#### Request

```json
{ "email": "alex@example.com", "password": "not-returned-or-logged" }
```

#### Response · 200

```json
{
  "status": { "code": "SUCCESS", "message": "Success" },
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiIs…",
    "refreshToken": "eyJhbGciOiJSUzI1NiIs…",
    "expiresIn": 900,
    "user": {
      "id": "49c694e7-0ca5-4eca-a112-f7b4709318ca",
      "name": "Alex Morgan",
      "email": "alex@example.com",
      "phone": "+855 12 345 678",
      "role": "user"
    }
  },
  "common": { "requestId": "0f2c…", "apiId": "AUT-0201", "timestamp": "2026-08-24T04:12:00Z" }
}
```

`expiresIn` is the access-token lifetime in seconds. Passwords and password hashes never appear in a
response. Where tokens are stored on the client remains a security implementation decision.

### 4.2 `POST /auth/register` · `AUT-0202`

Returns 201, or `VALIDATION_ERROR`, `EMAIL_ALREADY_REGISTERED`.

#### Request

```json
{
  "name": "Alex Morgan",
  "email": "alex@example.com",
  "password": "not-returned-or-logged"
}
```

#### Response · 201

Returns the same token-pair and `user` shape as login because successful v1 registration signs the
new user in immediately. `name` is required because the prototype collects Full name. The prototype's
`confirm password` input is client-side equality validation and is not sent or stored. API passwords
must be 8–72 UTF-8 characters; the prototype's current six-character HTML hint must be corrected
before it becomes a real client. Email verification and consent capture are deferred.

### 4.2.1 Token lifecycle · `AUT-0203`, `AUT-0205`

Refresh request:

```json
{ "refreshToken": "eyJhbGciOiJSUzI1NiIs…" }
```

`AUT-0203` returns 200 with a newly issued token pair:

```json
{ "accessToken": "eyJ…", "refreshToken": "eyJ…", "expiresIn": 900 }
```

Previously issued refresh tokens remain valid until their individual JWT expiration or account
logout. `AUT-0205` has no request body: it uses the authenticated access token and increments the
user's token version. This invalidates every access and refresh token previously issued to that
account on all devices. The client must also discard its locally stored tokens.

### 4.2.2 Password recovery · `AUT-0204`

Request: `{ "email": "alex@example.com" }`. The endpoint always returns 200 with `data: {}` for a
well-formed email so account existence is not disclosed. Delivery and reset-completion endpoints are
deferred.

### 4.2.3 Current identity · `AUT-0601`

Returns the `UserIdentity` shape used by login: `id`, `name`, `email`, nullable `phone`, and `role`.
It contains authentication identity only; profile counters are returned by `USR-0601`.

### 4.2.4 `GET /me/profile` · `USR-0601`

Returns `UserProfile`, which extends `UserIdentity` with timestamps and the prototype navigation
counts:

```json
{
  "id": "49c694e7-0ca5-4eca-a112-f7b4709318ca",
  "name": "Alex Morgan",
  "email": "alex@example.com",
  "phone": "+855 12 345 678",
  "role": "user",
  "memberSince": "2026-01-10T09:00:00Z",
  "counts": { "orders": 3, "wishlistItems": 2, "cartItems": 2 },
  "createdAt": "2026-01-10T09:00:00Z",
  "updatedAt": "2026-08-24T04:12:00Z"
}
```

`memberSince` equals `createdAt` and exists as a display-semantic alias; the client formats its year.
`cartItems` is the sum of cart quantities. Initials are derived from `name`. The prototype member
benefit is promotional mock copy and is not returned in v1.

### 4.3 `PATCH /me/profile` · `USR-0401`

Returns 200, or `VALIDATION_ERROR`, `EMAIL_ALREADY_REGISTERED`. `name`, `email`, and `phone` match the
current prototype; avatar support is not part of this contract. The scaffold currently stores names
up to 100 characters, which is the API limit.

#### Request

```json
{ "name": "Alex Morgan", "phone": "+855 12 345 678" }
```

Omitted fields remain unchanged. An empty `phone` clears it; name and email cannot be cleared.

#### Response · 200

```json
{
  "status": { "code": "SUCCESS", "message": "Success" },
  "data": {
    "id": "49c694e7-0ca5-4eca-a112-f7b4709318ca",
    "name": "Alex Morgan",
    "email": "alex@example.com",
    "phone": "+855 12 345 678",
    "role": "user",
    "memberSince": "2026-01-10T09:00:00Z",
    "counts": { "orders": 3, "wishlistItems": 2, "cartItems": 2 },
    "createdAt": "2026-01-10T09:00:00Z",
    "updatedAt": "2026-08-24T04:12:00Z"
  },
  "common": { "requestId": "0f2c…", "apiId": "USR-0401", "timestamp": "2026-08-24T04:12:00Z" }
}
```

### 4.3.1 `GET /categories` · `CAT-0101`

Returns active categories ordered by `name,asc,id,asc`:

```json
[
  { "id": "6955d229-d4f1-47a9-914c-9a2978e87d47", "name": "Accessories", "slug": "accessories" },
  { "id": "0fb0b3fd-0f63-4074-b524-b6e969395710", "name": "Footwear", "slug": "footwear" }
]
```

The prototype's `All` option is client-owned and is not a category row. Category symbols are also
presentation choices rather than API fields.

### 4.4 `GET /products` · `CAT-0102`

Returns `Pagination<ProductSummary>` with 200, or `VALIDATION_ERROR`, `CATEGORY_NOT_FOUND`.

#### Request

`?page=0&size=20&sort=featured,asc&query=watch&categoryId=<uuid>&inStock=true`

#### Response · 200

```json
{
  "status": { "code": "SUCCESS", "message": "Success" },
  "data": {
    "items": [
      {
        "id": "71d23f29-8e83-447d-b341-1cb0f2ef9151",
        "name": "Minimal Watch",
        "category": { "id": "6955d229-d4f1-47a9-914c-9a2978e87d47", "name": "Accessories" },
        "price": { "amount": "89.00", "currency": "USD" },
        "availableQuantity": 8,
        "rating": "4.8",
        "imageUrl": "https://cdn.example.com/products/minimal-watch.jpg",
        "badges": ["new", "premium_pick"],
        "featured": true
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1,
    "hasNext": false
  },
  "common": { "requestId": "0f2c…", "apiId": "CAT-0102", "timestamp": "2026-08-24T04:12:00Z" }
}
```

The list omits `description`; product details returns it as nullable. `inStock` is derived as
`availableQuantity > 0`. `badges` is an empty array when no merchandising label applies. A client
may choose the context-appropriate badge—for example `new` on a card and `premium_pick` in details.
Featured sorting places featured products by
`featuredRank`, followed by non-featured products and a stable ID tie-breaker. Rating is retained
because the prototype displays and sorts it, but its review source is deferred.

### 4.5 `GET /products/{productId}` · `CAT-0601`

Returns 200 or `PRODUCT_NOT_FOUND`. The response uses all product-summary fields plus nullable
`description`. `availableQuantity = 0` means out of stock; no duplicate availability flag is returned.
The quantity picker is client state and is sent only when adding to the cart.

### 4.6 `POST /cart/items` · `CRT-0201`

Returns the complete updated cart with 200, or `PRODUCT_NOT_FOUND`, `PRODUCT_OUT_OF_STOCK`,
`INSUFFICIENT_STOCK`, `VALIDATION_ERROR`.

#### Request

```json
{ "productId": "71d23f29-8e83-447d-b341-1cb0f2ef9151", "quantity": 1 }
```

If the product already exists in the cart, the quantity is increased atomically. The resulting
quantity must not exceed current stock.

#### Cart response shape

```json
{
  "status": { "code": "SUCCESS", "message": "Success" },
  "data": {
    "id": "ef7d1dcf-20b3-43a9-93d4-649658093747",
    "items": [
      {
        "id": "04de6d0d-5456-44dd-972f-9d4d7c1f3db0",
        "product": {
          "id": "71d23f29-8e83-447d-b341-1cb0f2ef9151",
          "name": "Minimal Watch",
          "imageUrl": "https://cdn.example.com/products/minimal-watch.jpg",
          "availableQuantity": 8
        },
        "quantity": 1,
        "unitPrice": { "amount": "89.00", "currency": "USD" },
        "lineTotal": { "amount": "89.00", "currency": "USD" }
      }
    ],
    "subtotal": { "amount": "89.00", "currency": "USD" },
    "itemCount": 1,
    "updatedAt": "2026-08-24T04:12:00Z"
  },
  "common": { "requestId": "0f2c…", "apiId": "CRT-0201", "timestamp": "2026-08-24T04:12:00Z" }
}
```

`lineTotal`, `subtotal`, and `itemCount` are derived from current USD catalog prices. Delivery is
absent because it is calculated at checkout.

### 4.6.1 Cart reads and mutations · `CRT-0601`, `CRT-0401`, `CRT-0501`

`GET /cart` returns the same `Cart` shape. A user without a persisted cart receives 200 with
`id: null`, `items: []`, zero USD subtotal, `itemCount: 0`, and `updatedAt: null`; reading does not
need to create a row.

`PATCH /cart/items/{itemId}` sets, rather than increments, the quantity:

```json
{ "quantity": 2 }
```

Quantity must be an integer from 1 through the product's current `availableQuantity`. DELETE has no
body. Both mutations return the complete updated `Cart`, allowing the prototype's cards, subtotal,
and cart badge to update from one response. Cart item `id` is distinct from product `id`.

### 4.7 `POST /wishlist/items` · `WSH-0201`

Returns 201 when newly saved and 200 when already saved. Request:

```json
{ "productId": "71d23f29-8e83-447d-b341-1cb0f2ef9151" }
```

The response data is the product-summary shape. `GET /wishlist/items` returns
`Pagination<ProductSummary>` in newest-saved-first order. Unavailable products remain visible with
their current quantity.

`GET /wishlist/items` accepts `page` and `size`; its `totalElements` drives the prototype saved count.
`DELETE /wishlist/items/{productId}` has no body and returns `data: {}`. The path intentionally uses
the product UUID because wishlist rows have no public identity in v1.

### 4.8 `POST /orders/preview` · `ORD-0201`

Validates current cart contents and returns calculated amounts without creating an order. Returns
200, or `CART_EMPTY`, `INSUFFICIENT_STOCK`, `CHECKOUT_INVALID`.

#### Request

```json
{
  "delivery": {
    "recipientName": "Alex Morgan",
    "email": "alex@example.com",
    "address": "12 Riverside Street, Phnom Penh"
  },
  "deliveryMethod": "standard",
  "paymentMethod": "cash_on_delivery"
}
```

#### Response data

```json
{
  "items": [
    {
      "productId": "71d23f29-8e83-447d-b341-1cb0f2ef9151",
      "name": "Minimal Watch",
      "imageUrl": "https://cdn.example.com/products/minimal-watch.jpg",
      "quantity": 1,
      "unitPrice": { "amount": "89.00", "currency": "USD" },
      "lineTotal": { "amount": "89.00", "currency": "USD" }
    },
    {
      "productId": "c652547d-098a-4201-a1c7-d6d7b709d6e8",
      "name": "Canvas Backpack",
      "imageUrl": "https://cdn.example.com/products/canvas-backpack.jpg",
      "quantity": 2,
      "unitPrice": { "amount": "58.00", "currency": "USD" },
      "lineTotal": { "amount": "116.00", "currency": "USD" }
    }
  ],
  "deliveryMethod": "standard",
  "estimatedDelivery": "2–4 business days",
  "subtotal": { "amount": "205.00", "currency": "USD" },
  "deliveryFee": { "amount": "4.00", "currency": "USD" },
  "total": { "amount": "209.00", "currency": "USD" },
  "expiresAt": "2026-08-24T04:27:00Z"
}
```

Standard delivery is 2–4 business days and costs USD 4.00 in v1. The delivery window is configured
copy, while the selected method is stored when the order is created. The preview expiry is 15 minutes.

### 4.9 `POST /orders` · `ORD-0202`

Uses the same delivery and payment body as preview and requires `Idempotency-Key`. Returns the full
created order with 201, or `CART_EMPTY`, `INSUFFICIENT_STOCK`, `CHECKOUT_INVALID`, `CONFLICT`.

#### Response · 201

```json
{
  "status": { "code": "CREATED", "message": "Created" },
  "data": {
    "id": "70bbc04b-3e7a-4b9a-a97e-855e3bb9bd75",
    "reference": "MC-20481",
    "status": "pending",
    "items": [
      {
        "productId": "71d23f29-8e83-447d-b341-1cb0f2ef9151",
        "name": "Minimal Watch",
        "quantity": 1,
        "unitPrice": { "amount": "89.00", "currency": "USD" },
        "lineTotal": { "amount": "89.00", "currency": "USD" }
      }
    ],
    "delivery": {
      "recipientName": "Alex Morgan",
      "email": "alex@example.com",
      "address": "12 Riverside Street, Phnom Penh"
    },
    "deliveryMethod": "standard",
    "estimatedDelivery": "2–4 business days",
    "paymentMethod": "cash_on_delivery",
    "subtotal": { "amount": "89.00", "currency": "USD" },
    "deliveryFee": { "amount": "4.00", "currency": "USD" },
    "total": { "amount": "93.00", "currency": "USD" },
    "createdAt": "2026-08-24T04:12:00Z"
  },
  "common": { "requestId": "0f2c…", "apiId": "ORD-0202", "timestamp": "2026-08-24T04:12:00Z" }
}
```

Order item names and prices are snapshots and do not change when the product changes. The server
calculates every amount; client-supplied totals are ignored. On success, the purchased cart items are
removed in the same transaction.

### 4.10 `GET /orders` · `ORD-0101`

Returns `Pagination<OrderSummary>` sorted by `createdAt,desc,id,desc`. Summaries contain `id`,
`reference`, `status`, `itemCount`, `total`, and `createdAt`; item lines appear only in
`GET /orders/{orderId}`.

The optional `status=pending|confirmed|shipped|delivered` filter can back a future status filter
without changing the prototype. `itemCount` is the sum of order-item quantities, matching the
prototype's “N items/products” label.

### 4.10.1 `GET /orders/{orderId}` · `ORD-0601`

Returns the `OrderDetail` shape shown for order creation, including item snapshots, delivery,
`deliveryMethod`, `estimatedDelivery`, payment method, amounts, and `createdAt`. It also includes
`updatedAt`. Shipment steps are derived from `status`: confirmed activates Confirmed, shipped
activates Confirmed and Shipped, and delivered activates all three prototype steps. A pending order
activates none of those fulfillment steps.

The endpoint returns `ORDER_NOT_FOUND` for both a missing order and an order owned by another user.
It never falls back to the hard-coded address or payment values currently shown by the mock.

### 4.11 `GET /notifications` · `NTF-0101`

Returns `Pagination<NotificationResponse>` with 200. Notifications are owner-scoped and newest first.

#### Request

`?page=0&size=20&filter=all`

#### Response · 200

```json
{
  "status": { "code": "SUCCESS", "message": "Success" },
  "data": {
    "items": [
      {
        "id": "22793c92-4fd4-48c2-b68f-a51ab41008a8",
        "type": "order",
        "title": "Your order is on the way",
        "message": "Order #MC-19842 has shipped and is moving toward Phnom Penh.",
        "readAt": null,
        "createdAt": "2026-08-27T03:30:00Z"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1,
    "hasNext": false
  },
  "common": { "requestId": "0f2c…", "apiId": "NTF-0101", "timestamp": "2026-08-27T04:12:00Z" }
}
```

`readAt = null` means unread. Cleared notifications are absent.

`createdAt` is the source for prototype relative labels such as “2 hours ago”; the API returns an
absolute timestamp so clients can localize it.

### 4.11.1 `GET /notifications/unread-count` · `NTF-0601`

Returns `{ "unreadCount": 2 }`. The count includes only rows where both `readAt` and `clearedAt` are
null and drives the header dot/count. It is not a stored notification field.

### 4.12 Notification mutations · `NTF-0201`, `NTF-0202`, `NTF-0501`

The three endpoints have no request body. Marking an already-read notification is idempotent.
`NTF-0201` returns the updated `Notification` and returns `NOTIFICATION_NOT_FOUND` when the id is
absent, cleared, or owned by another user.

Mark-all returns `{ "updatedCount": 2, "unreadCount": 0 }`. Clear-all soft-clears every visible row
and returns `{ "clearedCount": 3, "unreadCount": 0 }`. Both bulk operations return zero counts when
the inbox is already in the target state. These counts let the prototype update without another read.

## 5. Domain error catalogue

| Code | HTTP | Type | Implementation | Raised when |
|---|---:|---|---|---|
| `INVALID_CREDENTIALS` | 401 | AUTHENTICATION | Implemented in shared catalogue | Email or password does not match. |
| `ACCOUNT_DISABLED` | 401 | AUTHENTICATION | Implemented in shared catalogue | Credentials match an inactive account. |
| `EMAIL_ALREADY_REGISTERED` | 409 | CONFLICT | Implemented with auth | The normalized email already belongs to an account. |
| `INVALID_REFRESH_TOKEN` | 401 | AUTHENTICATION | Implemented with auth | Refresh token is malformed, expired, has the wrong type, or does not identify a current user. |
| `USER_NOT_FOUND` | 404 | NOT_FOUND | Implemented with current identity | Current account no longer resolves. |
| `PRODUCT_NOT_FOUND` | 404 | NOT_FOUND | Planned with catalog | Product is missing or not visible. |
| `CATEGORY_NOT_FOUND` | 404 | NOT_FOUND | Planned with catalog | Category filter does not resolve to an active category. |
| `CART_NOT_FOUND` | 404 | NOT_FOUND | Planned with cart | Current user has no resolvable cart. |
| `CART_ITEM_NOT_FOUND` | 404 | NOT_FOUND | Planned with cart | Item is absent or belongs to another cart. |
| `PRODUCT_OUT_OF_STOCK` | 409 | CONFLICT | Planned with cart | Available quantity is zero. |
| `INSUFFICIENT_STOCK` | 409 | CONFLICT | Planned with cart/order | Requested quantity exceeds current availability. |
| `WISHLIST_ITEM_NOT_FOUND` | 404 | NOT_FOUND | Planned with wishlist | Product is not in the current user’s wishlist. |
| `ORDER_NOT_FOUND` | 404 | NOT_FOUND | Planned with orders | Order is absent or belongs to another user. |
| `CART_EMPTY` | 409 | CONFLICT | Planned with orders | Checkout was requested with no cart items. |
| `CHECKOUT_INVALID` | 400 | VALIDATION | Planned with orders | Delivery or payment input is incomplete/unsupported. |
| `NOTIFICATION_NOT_FOUND` | 404 | NOT_FOUND | Planned with notifications | Notification is absent, cleared, or belongs to another user. |

## 6. Template for a new endpoint

````markdown
### `<METHOD> /<path>` · `<AREA>-<NNNN>`

<Auth requirement>. Returns <success status>, or `<ERROR>`, `<ERROR>`.

#### Request

<Explain partial, omitted, nullable, derived, or server-owned fields.>

```json
{}
```

#### Response · <status>

```json
{
  "status": { "code": "SUCCESS", "message": "Success" },
  "data": {},
  "common": { "requestId": "…", "apiId": "<AREA>-<NNNN>", "timestamp": "…" }
}
```
````

### Endpoint checklist

- [ ] ApiId is unique and in the correct number class.
- [ ] Authentication and ownership scope are explicit.
- [ ] Request and response include realistic values and the full envelope.
- [ ] All errors exist in both this document and [API conventions](api-convention.md).
- [ ] PATCH, nullable, absent, and derived fields are explained.
- [ ] Lists state pagination, filters, sorting, and a unique tie-breaker.
- [ ] The contract agrees with [Data model](data-model.md).
