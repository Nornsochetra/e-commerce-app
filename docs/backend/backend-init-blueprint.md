---
spec: SPEC-BACKEND-INIT
title: Backend Initialization Blueprint
status: approved-for-init
owner: Backend
depends_on: [SPEC-BACKEND-STRUCTURE, SPEC-API-CONVENTIONS, SPEC-DATA-MODEL]
last_updated: 2026-08-27
---

# Backend initialization blueprint

Initialization contract for the Mercato Spring Boot backend. This phase builds the shared spine,
identity persistence, and health endpoint. It does not implement catalog, cart, wishlist, order, or
notification feature controllers.

Companion documents:

- [Backend patterns](backend-patterns.md)
- [API conventions](../api-convention.md)
- [API specification](../api-specification.md)
- [Data model](../data-model.md)

## 1. Fixed project identity

| Setting | Value |
|---|---|
| Base package | `com.mercato.api` |
| Gradle group | `com.mercato` |
| Artifact/root project | `mercato-api` |
| Application name | `mercato-api` |
| JWT issuer | `mercato-api` |
| Development database | `mercato_dev` |
| Base API path | `/api/v1` |
| Initial role model | Authenticated customer only; admin authorization arrives with an admin feature |

Do not initialize under `com.example`, and do not copy example-domain classes into the project.

## 2. What initialization delivers

```text
A backend that:
  • starts locally with documented development configuration
  • applies and validates the identity migrations
  • returns one response envelope for success and failure
  • stamps requestId and ApiId on responses and logs
  • authenticates RS256 access tokens
  • distinguishes missing, invalid, and forbidden credentials
  • rotates and revokes persisted refresh sessions
  • masks credentials and tokens in logs
  • exposes only GET /api/v1/health as an initial controller
```

Login, registration, refresh, recovery, and logout are the first feature slice built after this
spine. The shared security components they require are initialized here.

## 3. Definition of done

- [ ] Gradle wrapper, build, formatting, and test tasks succeed.
- [ ] Application starts with the `dev` profile against PostgreSQL.
- [ ] Flyway applies `V1__create_users.sql` and `V2__create_refresh_sessions.sql`.
- [ ] Hibernate validates the migrated schema and does not create or alter it.
- [ ] `GET /api/v1/health` returns HTTP 200 in the standard envelope with `HLT-0601`.
- [ ] An unknown protected route without credentials returns envelope code `UNAUTHORIZED`.
- [ ] A malformed/expired access token returns `INVALID_TOKEN`.
- [ ] Security authorization failures return `FORBIDDEN` in the envelope.
- [ ] Tests start without requiring developer secrets.
- [ ] No password, token, private key, connection string, or `.env` file is committed.
- [ ] Logs contain request and ApiId context but mask sensitive values.

## 4. Initial project tree

```text
backend/
├── build.gradle
├── settings.gradle
├── gradlew
├── gradlew.bat
├── gradle/wrapper/
├── .env.example
├── .gitignore
└── src/
    ├── main/
    │   ├── java/com/mercato/api/
    │   │   ├── Application.java
    │   │   ├── config/
    │   │   │   ├── SecurityConfig.java
    │   │   │   └── OpenApiConfig.java
    │   │   ├── health/
    │   │   │   ├── controller/HealthController.java
    │   │   │   └── payload/HealthResponse.java
    │   │   └── shared/
    │   │       ├── api/
    │   │       ├── domain/
    │   │       ├── enums/
    │   │       ├── repository/
    │   │       ├── exception/
    │   │       ├── filter/
    │   │       ├── security/
    │   │       ├── helper/
    │   │       ├── properties/
    │   │       └── logging/
    │   └── resources/
    │       ├── application.yml
    │       ├── application-dev.yml
    │       ├── logback-spring.xml
    │       └── db/migration/
    │           ├── V1__create_users.sql
    │           └── V2__create_refresh_sessions.sql
    └── test/
        ├── java/com/mercato/api/
        └── resources/application-test.yml
```

Feature packages are added only when their feature implementation begins.

## 5. Build baseline

Use the Gradle wrapper and Java 21 toolchain. Pin mutually compatible stable versions during
initialization.

Required capabilities:

| Scope | Dependencies/capabilities |
|---|---|
| Application | Spring Web MVC, Validation, Data JPA, Security, OAuth2 Resource Server |
| Schema | Flyway core and PostgreSQL support |
| Database | PostgreSQL driver |
| API docs | Spring-compatible OpenAPI UI |
| Boilerplate | Lombok if retained by the team |
| Formatting | Spotless with one Java formatter |
| Test | Spring test, security test, MockMvc, JUnit 5 |

The default artifact is an executable JAR unless deployment explicitly requires a standalone servlet
container. Do not configure WAR packaging merely because the project-neutral example used it.

Required checks:

```bash
./gradlew spotlessCheck test build
```

## 6. Configuration

### 6.1 Shared `application.yml`

| Key | Required value or source |
|---|---|
| `spring.application.name` | `mercato-api` |
| `spring.profiles.default` | `dev` |
| `spring.datasource.*` | Environment variables; development defaults live only in dev profile |
| `spring.jpa.open-in-view` | `false` |
| `spring.jpa.hibernate.ddl-auto` | `validate` |
| `spring.jpa.properties.hibernate.jdbc.time_zone` | `UTC` |
| `spring.flyway.enabled` | `true` |
| `spring.flyway.locations` | `classpath:db/migration` |
| `spring.data.web.pageable.max-page-size` | `100` |
| `server.port` | `${SERVER_PORT:8080}` |
| `app.jwt.issuer` | `mercato-api` |
| `app.jwt.access-token-ttl` | `PT15M` |
| `app.jwt.refresh-token-ttl` | `P7D` |
| `app.jwt.public-key` | `${RSA_PUBLIC_KEY:}` resource location |
| `app.jwt.private-key` | `${RSA_PRIVATE_KEY:}` resource location |
| `app.cors.allowed-origins` | `${CORS_ALLOWED_ORIGINS:}` |

Secret defaults are empty. A non-secret development database default may exist in
`application-dev.yml`; deployed profiles must supply all connection values.

### 6.2 Profiles

- `dev`: local PostgreSQL, optional SQL logging, optional ephemeral RSA keypair.
- `test`: isolated test database/configuration and ephemeral RSA keypair.
- Deployed profiles: no database defaults, no ephemeral keys, no request/response body logging, and
  API documentation disabled unless explicitly secured.

Ephemeral RSA keys are allowed only for `dev` and `test`. Any other profile fails startup when key
locations are missing.

### 6.3 `.env.example` and ignore rules

Document variable names without values:

```text
SPRING_PROFILES_ACTIVE
DATABASE_URL
DATABASE_USERNAME
DATABASE_PASSWORD
RSA_PUBLIC_KEY
RSA_PRIVATE_KEY
CORS_ALLOWED_ORIGINS
LOG_DIR
```

Ignore `.env`, `logs/`, private key files, IDE secrets, build output, and local database artifacts.

## 7. Identity migrations

Use the DDL in [data-model.md](../data-model.md#51-identity--v1-and-v2):

- `V1__create_users.sql`
- `V2__create_refresh_sessions.sql`

Rules:

- Migrations are applied sequentially and never edited after application.
- Email uniqueness is the functional `lower(email)` index.
- Password hashes are adaptive one-way hashes with work factor at least 10.
- Refresh sessions store token hashes/identifiers, not raw refresh tokens.
- Do not seed reusable production credentials. Optional dev seed accounts use reserved
  `@example.com` addresses and locally documented passwords.

## 8. Shared API spine

Implement the exact wire behavior in [API conventions](../api-convention.md).

### 8.1 Core types

| Type | Purpose |
|---|---|
| `ApiResponse<T>` | Success/failure envelope |
| `ApiStatus` | Stable code and developer message |
| `ApiError` | Code, type, message, and optional details |
| `ApiErrorDetail` | Field validation detail with sensitive-value redaction |
| `CommonBlock` | Request id, ApiId, UTC timestamp |
| `ErrorType` | Error category enum |
| `StatusCode` | Only HTTP/error mapping catalogue |
| `BaseController` | `ok`, `created`, `accepted`, and empty-success helpers |
| `ApiId` | Endpoint annotation |
| `EmptyJsonResponse` | Serializes as `{}` |
| `Pagination<T>` | Stable project-owned page representation |

`ApiResponse` omits `data` on failure and `error` on success. Empty successful mutations return HTTP
200 with `data: {}`.

### 8.2 Initial status codes

Initialize every universal code from [API conventions](../api-convention.md#21-universal-codes) plus:

- `INVALID_CREDENTIALS`
- `ACCOUNT_DISABLED`
- `EMAIL_ALREADY_REGISTERED`
- `INVALID_REFRESH_TOKEN`

Feature-domain codes arrive with their feature slice. Adding an error means adding a status constant,
not a new exception class.

### 8.3 Exception handling

One global handler maps:

- Business exceptions
- Body and parameter validation
- Unreadable JSON and invalid enums
- Unsupported method/media type
- Missing route/resource
- Data-integrity conflicts
- Payload-too-large failures
- Unexpected exceptions

Validation returns one detail per rejected field. Values for password, secret, token, credential, and
authorization fields are never echoed.

## 9. Request tracing and logging

### 9.1 Trace filter

- Accept a valid inbound `X-Request-Id` or generate a UUID.
- Resolve ApiId from the handler annotation; unresolved handlers use `UNKNOWN`.
- Put both values into response headers, envelope context, and logging context.
- Clear thread-local/log context in `finally`.

### 9.2 Access logging

- Log method, path, status, duration, request id, and ApiId.
- Development may log bounded JSON bodies for local debugging.
- Other profiles log metadata only.
- Header logging uses an allow-list and excludes authorization/cookies.
- Streaming and binary responses are never buffered for logging.
- Redact keys containing password, secret, token, credential, authorization, bearer, API key, access
  key, or private key at log-render time.

## 10. JWT and refresh-session security

### 10.1 Token rules

- Sign and verify with RS256.
- Access token lifetime is 15 minutes.
- Refresh-session lifetime is 7 days.
- Both tokens carry distinct token types; a refresh token cannot authenticate an API request.
- Validate signature, issuer, expiry, and token type.
- Malformed, expired, or untrusted access tokens all return `INVALID_TOKEN`.

### 10.2 Refresh rotation

The auth feature later implements rotation using `refresh_sessions`:

1. Hash/identify the presented refresh token.
2. Load an active, unexpired session for the subject.
3. Revoke it and create its replacement in one transaction.
4. Link the old row through `replaced_by_id`.
5. Reject reuse as `INVALID_REFRESH_TOKEN` and revoke the affected chain according to the auth test.

Logout revokes the current refresh session. Registration and login create a fresh session.

### 10.3 Security routes

The initial public allow-list contains only health and OpenAPI development paths. As features arrive,
add exactly these public application routes:

```text
POST /api/v1/auth/login
POST /api/v1/auth/register
POST /api/v1/auth/refresh
POST /api/v1/auth/forgot-password
GET  /api/v1/categories
GET  /api/v1/products
GET  /api/v1/products/**
```

Logout, profile, cart, wishlist, orders, and notifications remain protected.

Security-chain 401/403 responses use the same envelope as controller responses.

## 11. Health endpoint

```text
GET /api/v1/health
ApiId: HLT-0601
Authentication: public
HTTP: 200
```

Response data:

```json
{
  "status": "up",
  "service": "mercato-api"
}
```

The complete HTTP response includes the standard envelope and common block.

## 12. Initialization tests

Minimum test coverage:

| Test | Assertion |
|---|---|
| Health | 200, envelope, `HLT-0601`, request id, UTC timestamp |
| Success serialization | `error` absent |
| Failure serialization | `data` absent |
| Empty success | 200 with `{}` data |
| Validation | One detail per field; secret values absent |
| No token | 401 `UNAUTHORIZED` envelope |
| Invalid token | 401 `INVALID_TOKEN` envelope |
| Refresh token as bearer | 401 `INVALID_TOKEN` |
| Authorization failure | 403 `FORBIDDEN` envelope |
| Unknown route | 404 `NOT_FOUND` envelope |
| Trace cleanup | Request context does not leak between requests |
| Log masking | Password/token variants are redacted |
| Email uniqueness | Case-insensitive duplicates fail |

Do not mock the token parser in security integration tests; generate real test tokens using the test
keypair.

## 13. Initialization order

1. Generate Gradle wrapper and build configuration.
2. Add shared/dev/test configuration and ignore rules.
3. Add application entry point.
4. Add identity migrations and matching entities/repositories.
5. Add API envelope, status catalogue, and controller helpers.
6. Add global exception handling.
7. Add trace context and logging filters.
8. Add RSA key loading, JWT provider/filter, and envelope security writers.
9. Add security and OpenAPI configuration.
10. Add the health endpoint.
11. Add initialization tests.
12. Run formatting, tests, build, migration boot, and manual health/security checks.

## 14. Build next

After initialization, implement slices in this order:

1. Authentication and profile
2. Catalog
3. Cart
4. Wishlist
5. Orders and checkout
6. Notifications

Each slice follows [backend patterns](backend-patterns.md#9-adding-a-feature-or-endpoint) and its
contract in [API specification](../api-specification.md).
