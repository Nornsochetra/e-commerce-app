---
spec: SPEC-API-CONVENTIONS
title: API Conventions
status: draft
owner: Backend
last_updated: 2026-08-24
---

# API conventions

Cross-cutting rules for every endpoint in the e-commerce API. Feature contracts inherit these rules
and must not redefine them locally.

Base path: `/api/v1`. Companion documents:

- [API specification](api-specification.md) — feature areas and endpoint contracts.
- [Data model](data-model.md) — entities, relationships, constraints, and proposed schema.
- [Backend patterns](backend/backend-patterns.md) — implementation structure and layer boundaries.

> **Status:** This is a draft contract derived from the approved feature requirements and the
> documentation pattern in `docs-example`. Decisions marked **TBD** require product or backend
> approval before production implementation.

## 1. Response envelope

Every JSON response, successful or failed, uses `ApiResponse<T>`.

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

- `data` is omitted on failure.
- `error` is omitted on success.
- `common.requestId` identifies one request across responses and logs.
- `common.apiId` is the endpoint identifier defined in the API specification.
- Raw files and images may bypass the envelope only when their endpoint explicitly documents it.

### 1.1 Success statuses

| HTTP | `status.code` | Use |
|---|---|---|
| 200 | `SUCCESS` | Reads, updates, completed actions, and empty `{}` responses. |
| 201 | `CREATED` | A newly addressable resource. Return the created resource. |
| 202 | `ACCEPTED` | Only persisted asynchronous work with a pollable job resource. |

An empty successful response is HTTP 200 with `data: {}`, not HTTP 204, so the client always receives
the same parseable envelope.

### 1.2 The 202 rule

A 202 response is permitted only when all three conditions are true:

1. The work is persisted as a job before the response is returned.
2. The response contains that job in its current state.
3. A documented `GET` endpoint lets the client poll the job.

| ApiId | Endpoint | Job resource | Poll endpoint |
|---|---|---|---|
| _(none)_ | | | |

## 2. Errors

Failures use one stable machine-readable code. The frontend resolves user-facing copy from that code;
`status.message` and `error.message` are developer-facing English and must not be shown directly.

```json
{
  "status": { "code": "PRODUCT_NOT_FOUND", "message": "Product was not found" },
  "common": {
    "requestId": "0f2c9e14-6b8a-4d31-9f77-2c1e5a90b4d3",
    "apiId": "CAT-0601",
    "timestamp": "2026-08-24T04:12:00Z"
  },
  "error": {
    "code": "PRODUCT_NOT_FOUND",
    "type": "NOT_FOUND",
    "message": "Product was not found"
  }
}
```

Allowed `error.type` values are:

`NONE · VALIDATION · AUTHENTICATION · AUTHORIZATION · NOT_FOUND · CONFLICT · SYSTEM`

Validation failures include one detail per rejected field. Rejected values for fields containing
`password`, `secret`, or `token` must never be returned.

```json
{
  "status": { "code": "VALIDATION_ERROR", "message": "Validation failed" },
  "common": { "requestId": "0f2c…", "apiId": "CRT-0401", "timestamp": "2026-08-24T04:12:00Z" },
  "error": {
    "code": "VALIDATION_ERROR",
    "type": "VALIDATION",
    "message": "Validation failed",
    "details": [
      { "field": "quantity", "message": "Quantity must be at least 1", "rejectedValue": 0 }
    ]
  }
}
```

### 2.1 Universal codes

| Code | HTTP | `ErrorType` |
|---|---:|---|
| `SUCCESS` · `CREATED` · `ACCEPTED` | 200 · 201 · 202 | `NONE` |
| `INVALID_REQUEST` · `VALIDATION_ERROR` | 400 | `VALIDATION` |
| `UNAUTHORIZED` · `INVALID_TOKEN` | 401 | `AUTHENTICATION` |
| `FORBIDDEN` | 403 | `AUTHORIZATION` |
| `NOT_FOUND` | 404 | `NOT_FOUND` |
| `METHOD_NOT_ALLOWED` | 405 | `VALIDATION` |
| `NOT_ACCEPTABLE` | 406 | `VALIDATION` |
| `DUPLICATE` · `CONFLICT` | 409 | `CONFLICT` |
| `PAYLOAD_TOO_LARGE` | 413 | `VALIDATION` |
| `UNSUPPORTED_MEDIA_TYPE` | 415 | `VALIDATION` |
| `INTERNAL_ERROR` | 500 | `SYSTEM` |

### 2.2 Domain codes

Domain codes are added here when the corresponding endpoint contract is approved.

| Area | Codes currently reserved |
|---|---|
| `AUT` | `INVALID_CREDENTIALS`, `ACCOUNT_DISABLED`, `EMAIL_ALREADY_REGISTERED`, `INVALID_REFRESH_TOKEN` |
| `USR` | `USER_NOT_FOUND`, `EMAIL_ALREADY_REGISTERED` |
| `CAT` | `PRODUCT_NOT_FOUND`, `CATEGORY_NOT_FOUND` |
| `CRT` | `CART_NOT_FOUND`, `CART_ITEM_NOT_FOUND`, `PRODUCT_OUT_OF_STOCK`, `INSUFFICIENT_STOCK` |
| `WSH` | `WISHLIST_ITEM_NOT_FOUND` |
| `ORD` | `ORDER_NOT_FOUND`, `CART_EMPTY`, `CHECKOUT_INVALID`, `INSUFFICIENT_STOCK` |
| `NTF` | `NOTIFICATION_NOT_FOUND` |

For user-owned resources, “does not exist” and “belongs to another user” return the same `*_NOT_FOUND`
code. A 403 would reveal that another user’s resource exists.

## 3. URLs and endpoint naming

- Paths are lowercase, plural nouns, and kebab-case where more than one word is required.
- Paths contain resources, not verbs: `POST /orders`, not `POST /createOrder`.
- Resource identifiers are UUIDs, never internal numeric primary keys.
- The authenticated user is represented by `/me`; clients never submit their own user id.
- Child resources nest when the parent defines ownership: `/cart/items/{itemId}`.
- Actions that are not CRUD use a final verb: `/auth/refresh`, `/auth/logout`.
- Every path in [api-specification.md](api-specification.md) is relative to `/api/v1`.

### 3.1 ApiId format

Every endpoint has a stable `ApiId` in the form `<AREA>-<NNNN>`.

| Number class | Operation |
|---|---|
| `01xx` | List |
| `02xx` | Create or action |
| `03xx` | Replace (`PUT`) |
| `04xx` | Partial update (`PATCH`) |
| `05xx` | Delete or remove |
| `06xx` | Get one |
| `07xx` | Stream |

Area codes: `HLT` health · `AUT` authentication · `USR` profile · `CAT` catalog · `CRT` cart ·
`WSH` wishlist · `ORD` orders · `NTF` notifications.

## 4. Requests

- JSON field names use `camelCase`; database names use `snake_case`.
- `Content-Type: application/json` is required for JSON bodies.
- Unknown request fields are ignored during the draft phase; changing this to strict rejection is TBD.
- Server-owned fields such as ids, totals, status, and timestamps are absent from create/update bodies.
- `PATCH` is partial: omitted or `null` means “leave unchanged”; an empty string means “clear” only
  for fields whose contract allows clearing.
- Request validation happens at the boundary and reports all field errors together.
- The authenticated caller comes from the access token, never from a `userId` body/query field.

## 5. Authentication and authorization

- Protected endpoints use `Authorization: Bearer <access-token>`.
- Login, registration, password-recovery request, token refresh, health, and catalog reads are public.
- Profile, cart, wishlist, order, and logout endpoints require authentication.
- An access token and refresh token are different credentials; a refresh token must never authorize a
  normal API request.
- `INVALID_CREDENTIALS` does not reveal whether the email or password was wrong.
- Passwords contain at least 8 characters. Access tokens last 15 minutes; refresh sessions last 7
  days and rotate on refresh.
- Registration creates a session immediately. Email verification is deferred.
- Cart and wishlist require authentication; guest persistence and merging are deferred.

## 6. Enumerated values

Wire values are lowercase `snake_case`. Stored values may use `UPPER_SNAKE`, with translation in one
shared serialization layer.

| Enum | Draft wire values | Ownership |
|---|---|---|
| Order status | `pending` · `confirmed` · `shipped` · `delivered` | Server-written, forward-only in v1. |
| Payment method | `cash_on_delivery` | V1 production method; card is prototype-only. |
| Notification type | `order` · `offer` · `stock` | Server-written. |
| Product availability | Derived from `availableQuantity` | Not stored as a second status. |

A display label is not a wire value. Localized strings such as “Cash on delivery” belong to the
client’s message catalogue.

## 7. Pagination, filtering, and sorting

Unbounded lists return `Pagination<T>` in `data`:

```json
{
  "items": [],
  "page": 0,
  "size": 20,
  "totalElements": 0,
  "totalPages": 0,
  "hasNext": false
}
```

- `page` is zero-based; default `size` is 20 and maximum is 100.
- Sorting uses `?sort=field,asc|desc` and only documented fields are accepted.
- Filters use explicit query parameters, for example `?categoryId=<uuid>&inStock=true`.
- Every paginated sort has a unique final tie-breaker, normally `id` descending.
- Product results, wishlist items, order history, and notifications are paginated. Categories and
  current cart items are unpaginated because they are rendered as one bounded client view.
- Totals and summaries are computed over the full matching set, never only the current page.

## 8. Date, time, money, and identifiers

| Value | Wire format |
|---|---|
| Timestamp | UTC ISO 8601, for example `2026-08-24T04:12:00Z` |
| Date without time | ISO 8601 `YYYY-MM-DD` |
| Money | Decimal JSON string with currency, for example `{ "amount": "89.00", "currency": "USD" }` |
| Public id | UUID string |

Money is never a floating-point value. V1 uses USD; multi-currency is deferred.

## 9. Idempotency and concurrency

- `GET`, `PUT`, and `DELETE` are idempotent by HTTP semantics.
- Order creation accepts `Idempotency-Key` so a retry cannot place the same order twice.
- The server validates stock again inside the order transaction; cart validation alone is not enough.
- Inventory reservation and optimistic locking are deferred. An order keeps its idempotency key for
  the life of the order; a compatible replay returns the original result and a different payload
  using the same key returns `CONFLICT`.

## 10. Contract checklist

- [ ] Unique ApiId in the correct number class.
- [ ] Authentication requirement stated.
- [ ] Request and full envelope response shown.
- [ ] Success status and every possible error code listed.
- [ ] Nullable, omitted, derived, and server-owned fields explained.
- [ ] Pagination/filter/sort behavior stated for list endpoints.
- [ ] Data-model fields and constraints match [data-model.md](data-model.md).
- [ ] No unresolved decision is presented as approved behavior.
