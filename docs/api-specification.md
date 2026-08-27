---
spec: SPEC-API
title: API Specification
status: draft
owner: Backend
depends_on: [SPEC-API-CONVENTIONS, SPEC-DATA-MODEL]
last_updated: 2026-08-24
---

# API specification

Endpoint contracts for the current e-commerce scope. Cross-cutting behavior—response envelopes,
errors, authentication, enum spelling, pagination, money, and timestamps—is defined in
[API conventions](api-convention.md). Database fields and ownership rules are defined in
[Data model](data-model.md).

> **Approval boundary:** Endpoint paths and payloads below are a proposed implementation contract.
> They are based on the approved screens and current prototype, but rules explicitly marked **TBD**
> are not production decisions.

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
| `HLT` | Service health | Infrastructure | Proposed |
| `AUT` | Login, registration, recovery, token lifecycle | Splash and authentication | Approved for v1 |
| `USR` | Current-user profile | Profile and edit profile | Approved for v1 |
| `CAT` | Categories, products, search, filters | Home and catalog | Approved for v1 |
| `CRT` | Current cart and items | Shopping cart | Approved for v1 |
| `WSH` | Current wishlist | Wishlist | Approved for v1 |
| `ORD` | Checkout and order history | Checkout, confirmation, orders | Approved for v1 |
| `NTF` | In-app notification inbox | Notifications and unread badge | Approved for v1 |

Public routes are health, auth entry routes, categories, and product reads. All other routes require
an access token. Cart, wishlist, checkout, orders, profile, and notifications are authenticated and
owner-scoped.

## 3. Endpoint inventory

### 3.1 `HLT` — health

| ApiId | Endpoint | Auth | Purpose |
|---|---|---|---|
| `HLT-0601` | `GET /health` | Public | Read service availability. |

### 3.2 `AUT` — authentication

| ApiId | Endpoint | Auth | Purpose |
|---|---|---|---|
| `AUT-0201` | `POST /auth/login` | Public | Exchange email/password for tokens and user. |
| `AUT-0202` | `POST /auth/register` | Public | Create an account. |
| `AUT-0203` | `POST /auth/refresh` | Refresh token | Rotate the token pair. |
| `AUT-0204` | `POST /auth/forgot-password` | Public | Begin account recovery without revealing account existence. |
| `AUT-0205` | `POST /auth/logout` | Access token | Revoke the current refresh session. |
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

`GET /products` accepts `page`, `size`, `sort`, `query`, `categoryId`, and `inStock`. Initially
supported sorts are `name,asc`, `price,asc`, `price,desc`, and `createdAt,desc`.

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

### 4.1 `POST /auth/login` · `AUT-0201`

Returns 200, or `VALIDATION_ERROR`, `INVALID_CREDENTIALS`, `ACCOUNT_DISABLED`.

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
      "phone": "+855 12 345 678"
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
new user in immediately. Email verification and consent capture are deferred.

### 4.3 `PATCH /me/profile` · `USR-0401`

Returns 200, or `VALIDATION_ERROR`, `EMAIL_ALREADY_REGISTERED`. `name`, `email`, and `phone` match the
current prototype; avatar support is not part of this contract.

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
    "createdAt": "2026-01-10T09:00:00Z",
    "updatedAt": "2026-08-24T04:12:00Z"
  },
  "common": { "requestId": "0f2c…", "apiId": "USR-0401", "timestamp": "2026-08-24T04:12:00Z" }
}
```

### 4.4 `GET /products` · `CAT-0102`

Returns `Pagination<ProductSummary>` with 200, or `INVALID_REQUEST`, `CATEGORY_NOT_FOUND`.

#### Request

`?page=0&size=20&sort=price,asc&query=watch&categoryId=<uuid>&inStock=true`

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
        "imageUrl": "https://cdn.example.com/products/minimal-watch.jpg"
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

The list omits `description`; product details returns it as nullable. Rating is retained because the
prototype displays it, but its source and review model are TBD.

### 4.5 `GET /products/{productId}` · `CAT-0601`

Returns 200 or `PRODUCT_NOT_FOUND`. The response uses the product summary fields plus nullable
`description`. `availableQuantity = 0` means out of stock; no duplicate availability flag is returned.

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

### 4.7 `POST /wishlist/items` · `WSH-0201`

Returns 201 when newly saved and 200 when already saved. Request:

```json
{ "productId": "71d23f29-8e83-447d-b341-1cb0f2ef9151" }
```

The response data is the product-summary shape. `GET /wishlist/items` returns
`Pagination<ProductSummary>` in newest-saved-first order. Unavailable products remain visible with
their current quantity.

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
  "paymentMethod": "cash_on_delivery"
}
```

#### Response data

```json
{
  "items": [],
  "subtotal": { "amount": "205.00", "currency": "USD" },
  "deliveryFee": { "amount": "4.00", "currency": "USD" },
  "total": { "amount": "209.00", "currency": "USD" },
  "expiresAt": "2026-08-24T04:27:00Z"
}
```

Standard delivery is 2–4 business days and costs USD 4.00 in v1. The preview expiry is 15 minutes.

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

### 4.12 Notification mutations · `NTF-0201`, `NTF-0202`, `NTF-0501`

The three endpoints have no request body and return 200 with `data: {}`. Marking an already-read
notification is idempotent. `NTF-0201` returns `NOTIFICATION_NOT_FOUND` when the id is absent, cleared,
or owned by another user. Mark-all and clear-all succeed when the inbox is already in the target state.

## 5. Domain error catalogue

| Code | HTTP | Type | Raised when |
|---|---:|---|---|
| `INVALID_CREDENTIALS` | 401 | AUTHENTICATION | Email or password does not match. |
| `ACCOUNT_DISABLED` | 401 | AUTHENTICATION | Credentials match an inactive account. |
| `EMAIL_ALREADY_REGISTERED` | 409 | CONFLICT | The normalized email already belongs to an account. |
| `INVALID_REFRESH_TOKEN` | 401 | AUTHENTICATION | Refresh token is invalid, expired, revoked, or reused. |
| `USER_NOT_FOUND` | 404 | NOT_FOUND | Current account no longer resolves. |
| `PRODUCT_NOT_FOUND` | 404 | NOT_FOUND | Product is missing or not visible. |
| `CATEGORY_NOT_FOUND` | 404 | NOT_FOUND | Category filter does not resolve to an active category. |
| `CART_NOT_FOUND` | 404 | NOT_FOUND | Current user has no resolvable cart. |
| `CART_ITEM_NOT_FOUND` | 404 | NOT_FOUND | Item is absent or belongs to another cart. |
| `PRODUCT_OUT_OF_STOCK` | 409 | CONFLICT | Available quantity is zero. |
| `INSUFFICIENT_STOCK` | 409 | CONFLICT | Requested quantity exceeds current availability. |
| `WISHLIST_ITEM_NOT_FOUND` | 404 | NOT_FOUND | Product is not in the current user’s wishlist. |
| `ORDER_NOT_FOUND` | 404 | NOT_FOUND | Order is absent or belongs to another user. |
| `CART_EMPTY` | 409 | CONFLICT | Checkout was requested with no cart items. |
| `CHECKOUT_INVALID` | 400 | VALIDATION | Delivery or payment input is incomplete/unsupported. |
| `NOTIFICATION_NOT_FOUND` | 404 | NOT_FOUND | Notification is absent, cleared, or belongs to another user. |

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
