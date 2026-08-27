---
spec: SPEC-BACKEND-STRUCTURE
title: Backend Patterns
status: approved-for-init
owner: Backend
depends_on: [SPEC-API-CONVENTIONS, SPEC-API, SPEC-DATA-MODEL]
last_updated: 2026-08-27
---

# Backend patterns

Project-specific package structure, dependency rules, and implementation patterns for the Mercato
e-commerce backend.

Companion documents:

- [Backend initialization blueprint](backend-init-blueprint.md)
- [API conventions](../api-convention.md)
- [API specification](../api-specification.md)
- [Data model](../data-model.md)
- [Use cases](../usecase.md)

## 1. Backend baseline

| Concern | Decision |
|---|---|
| Language/runtime | Java 21 |
| Framework | Spring Boot with Spring MVC, Validation, Security, and Data JPA |
| Build | Gradle wrapper |
| Database | PostgreSQL |
| Schema ownership | Flyway migrations; Hibernate validates only |
| Authentication | Stateless bearer access token plus rotating refresh sessions |
| API documentation | OpenAPI |
| Tests | JUnit 5, MockMvc, and PostgreSQL integration tests when migrations are exercised |
| Base package | `com.mercato.api` |
| Artifact/application | `mercato-api` |

Dependency versions are pinned when the backend is initialized and updated through a dedicated
dependency change, not silently inside feature work.

## 2. Vertical-slice package layout

```text
com.mercato.api
├── Application.java
├── config/
│   ├── SecurityConfig.java
│   ├── OpenApiConfig.java
│   └── WebConfig.java
├── health/
├── auth/
├── profile/
├── catalog/
├── cart/
├── wishlist/
├── order/
├── notification/
└── shared/
    ├── api/
    ├── domain/
    ├── enums/
    ├── repository/
    ├── exception/
    ├── filter/
    ├── security/
    ├── helper/
    ├── properties/
    └── logging/
```

Each feature slice normally contains:

```text
<slice>/
├── controller/
├── service/
├── mapper/
└── payload/
```

### 2.1 Slice and ApiId mapping

| Slice | ApiId area | Route root |
|---|---|---|
| `health` | `HLT` | `/api/v1/health` |
| `auth` | `AUT` | `/api/v1/auth` |
| `profile` | `USR` | `/api/v1/me` |
| `catalog` | `CAT` | `/api/v1/categories`, `/api/v1/products` |
| `cart` | `CRT` | `/api/v1/cart` |
| `wishlist` | `WSH` | `/api/v1/wishlist` |
| `order` | `ORD` | `/api/v1/orders` |
| `notification` | `NTF` | `/api/v1/notifications` |

The ApiId number class is fixed by [API conventions](../api-convention.md#31-apiid-format).

## 3. Placement and dependency rules

| Layer | May depend on | Must not depend on |
|---|---|---|
| Controller | Its service and payloads, `shared.api` | Repositories, entities, HTTP decisions outside the shared response helpers |
| Service | Repositories, entities, mapper, payloads, shared helpers | Servlet request/response objects |
| Mapper | Entities and its slice payloads | Repositories or services |
| Repository | Shared entities and enums | Feature services or API payloads |
| Shared | Other shared packages | Any feature slice |

Two placement rules prevent most dependency problems:

1. Entities, persisted enums, and repositories live in `shared` because multiple slices use them.
2. Request and response payloads belong to one slice and are never reused across slices.

An entity never appears in a controller signature or JSON response. A payload never appears in a
repository signature.

## 4. Request path

```text
TraceContextFilter
  └─ RequestLoggingFilter
      └─ JwtAuthenticationFilter
          └─ Route authentication
              └─ Controller
                  └─ Service transaction
                      ├─ Repository
                      └─ Mapper

GlobalExceptionHandler maps application exceptions to ApiResponse failures.
```

- Trace context is created before logging so every log line has `requestId` and `apiId`.
- A security filter writes envelope-shaped 401/403 responses because MVC exception handling cannot
  catch failures produced before the controller.
- Controllers return through shared `ok`, `created`, and empty-response helpers.
- Services throw one application exception carrying a shared status code; HTTP stays outside services.

## 5. Layer contracts

### 5.1 Controller

```java
@RestController
@RequestMapping("/api/v1/cart")
@RequiredArgsConstructor
class CartController extends BaseController {
  private final CartService cartService;

  @GetMapping
  @ApiId("CRT-0601")
  ResponseEntity<ApiResponse<CartResponse>> getCurrentCart() {
    return ok(cartService.getCurrentCart());
  }
}
```

- One ApiId per handler.
- Validate every request body.
- Delegate once and wrap the result.
- Do not put business logic, repositories, entities, `try/catch`, or manually selected HTTP statuses
  in controllers.
- The current user comes from security context, never a caller-supplied `userId`.

### 5.2 Service

- One transaction boundary per public operation; reads use read-only transactions.
- Resolve the current user through one shared resolver.
- Scope cart, wishlist, order, and notification queries by owner in the query itself.
- Throw `BusinessException(StatusCode.X)` for expected failures.
- Return mapped payloads, never managed entities.
- Order creation performs stock validation, snapshot creation, quantity decrement, cart cleanup, and
  idempotency handling in one transaction.

### 5.3 Repository

- Extend the project-standard JPA repository using internal `Long` ids.
- Public lookup methods accept UUID plus required owner/active scope.
- List queries use the exact stable sort documented in the API specification.
- Case-insensitive email queries use `lower(email)` so they match the functional unique index.
- A repository must not expose an unsafe unscoped lookup for an owner-scoped resource.

### 5.4 Mapper

- Convert entities to request-specific API payloads by hand.
- Expose public UUIDs, never numeric primary keys.
- Apply wire enum spelling in one shared serialization mechanism.
- Summary mappings must not touch associations that cause N+1 queries.
- PATCH mapping treats omitted/null as unchanged and a permitted empty string as cleared.

### 5.5 Payload

- Use one request or response type per file.
- Put boundary-validation annotations and clear messages on request fields.
- Exclude server-owned ids, totals, state, ownership, and timestamps from request bodies.
- Never expose entity, `Optional`, or framework page types on the wire.
- Money payloads use decimal strings plus `currency` as required by API conventions.

### 5.6 Entity

- Internal `Long id`; public UUID on addressable resources.
- Associations are lazy by default.
- Persist enums as strings, never ordinals.
- Match every database default in object construction.
- Do not add a mapped column without a Flyway migration.
- Historical `order_items` are immutable snapshots.
- Notification clear state uses `cleared_at`; it is not a hard delete operation.

## 6. Feature-specific invariants

| Slice | Invariant enforced by the service |
|---|---|
| Auth | Normalize email; rotate refresh sessions; never reveal which credential failed. |
| Catalog | Return active products in active categories only. |
| Cart | One line per product; quantity 1..available quantity; totals use current price. |
| Wishlist | One product per user; repeated save is idempotent. |
| Order | Validate/decrement stock and persist immutable price snapshots atomically. |
| Notification | Owner-scoped reads/mutations; read and clear operations are idempotent. |

## 7. Resources and migrations

```text
src/main/resources/
├── application.yml
├── application-dev.yml
├── logback-spring.xml
└── db/migration/
    ├── V1__create_users.sql
    ├── V2__create_refresh_sessions.sql
    ├── V3__create_catalog.sql
    ├── V4__create_cart_and_wishlist.sql
    ├── V5__create_orders.sql
    └── V6__create_notifications.sql
```

Applied migrations are immutable. Add a new migration for every later schema change and update
[data-model.md](../data-model.md) in the same change.

## 8. Testing pattern

Each endpoint slice has HTTP-level tests covering:

- Success response data, HTTP status, envelope, and ApiId.
- Validation details and rejected-secret redaction.
- Missing, invalid, and expired authentication.
- Owner isolation using two users.
- Documented not-found/conflict conditions.
- Stable pagination and filtering.
- Transaction rollback on a failed order.
- Idempotent retry for order creation and notification mutations.

Business-rule unit tests supplement HTTP tests where combinations are large. Migration tests use a
real PostgreSQL-compatible environment rather than relying only on an in-memory database.

## 9. Adding a feature or endpoint

1. Approve its feature requirement and use case.
2. Add or update its API contract and domain errors.
3. Add a migration when persistent state changes.
4. Add/update entity, enum, and repository types.
5. Add payloads and mapper.
6. Add transactional service behavior.
7. Add the controller and unique ApiId.
8. Add success, failure, security, and ownership tests.
9. Run formatting, tests, and the application startup check.

## 10. Structural anti-patterns

| Avoid | Use instead |
|---|---|
| Entity/repository inside a feature slice | `shared/domain` and `shared/repository` |
| Payload shared between slices | Slice-owned payloads |
| Entity serialized by a controller | Mapper-produced response |
| `findByUuid` followed by ownership `if` | Owner-scoped repository query |
| New exception class per error | Shared status code plus `BusinessException` |
| Raw framework page response | Project `Pagination<T>` |
| Numeric database id in API | Public UUID |
| Client-supplied totals/status/user id | Server-derived values |
| Hard delete of order history or notifications | Immutable snapshots or documented soft state |
| Feature code changing applied migrations | A new sequential migration |
