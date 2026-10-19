# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

Mercato is a mobile e-commerce app (Setec Institute year-4 project), split into three parts:

- `backend/` — Spring Boot 4 / Java 21 REST API (`com.setec.ecommerce`). **All v1 endpoints are implemented and tested.**
- `frontend-app/` — Flutter app (Android/iOS phones, portrait). **Not started:** `lib/main.dart` is still the default counter template.
- `docs/` — the source of truth for behavior. Read the relevant doc before changing a feature.
  - `requirement.md` (scope, screen inventory SCR-001…022, system-wide business rules), `usecase.md`, `features/*.md` (per-feature specs), `api-convention.md`, `api-specification.md` (every endpoint, keyed by ApiId), `data-model.md`, `backend/backend-patterns.md`.
  - `prototype/` — approved, clickable HTML UI prototype (React + Babel + Tailwind via CDN, mock data in `localStorage`). It is the visual spec for the Flutter screens. Opens from `file://` with no build step; see `prototype/README.md`.
    - One screen per HTML file (`splash.html`, `login.html`, `home.html`, `categories.html`, `product.html?id=…`, `cart.html`, `checkout.html`, `order-detail.html?id=…`, …). `index.html` only redirects to `splash.html`; `screens.html` lists every screen.
    - Shared code lives in `prototype/assets/`: `mercato.js` (plain JS, no JSX — mock data, `Mercato.to.*` link builders, and globals such as `ScreenLayout`, `AppHeader`, `TabBar`, `ProductCard`, `BottomSheet`, `TextField`) and `mercato.css` (design tokens + component classes, wrapped in `@layer components` so Tailwind utilities still override). Each screen file keeps its component inline in `<script type="text/babel">` and ends with `Mercato.mount(Screen)`, which re-renders on any data change and passes `params`/`query`, `navigate`, `goBack`.
    - Navigation: floating tab bar = Home, Categories, Wishlist, Cart, Profile (`<ScreenLayout active="…">`). Orders are reached from Profile, the Home order banner, notifications and the order confirmation. Product details and checkout hide the tab bar and use a sticky bottom action dock.

## Backend commands

Run from `backend/` (Gradle wrapper, Java 21 toolchain):

```bash
./gradlew test                                            # all tests
./gradlew test --tests 'com.setec.ecommerce.cart.CartApiTest'            # one class
./gradlew test --tests 'com.setec.ecommerce.cart.CartApiTest.<method>'   # one test
./gradlew spotlessApply                                   # format (google-java-format); spotlessCheck to verify
./gradlew bootRun                                         # needs PostgreSQL (see below)
```

Config comes from env vars (`backend/.env.example`: `SPRING_PROFILES_ACTIVE`, `DATABASE_URL`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`; also `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY`, `CORS_ALLOWED_ORIGINS`, `SERVER_PORT`). The `dev` profile (default) falls back to `postgresql://localhost:5432/e-commerce`. Swagger UI is at `/swagger-ui.html`.

## Frontend commands

Run from `frontend-app/`: `flutter pub get`, `flutter analyze`, `flutter test` (single: `flutter test test/<file>_test.dart`), `flutter run`. Lints come from `flutter_lints`.

## Backend architecture (read `docs/backend/backend-patterns.md` for the full rules)

- **Vertical slices** under `com.setec.ecommerce`: `auth`, `profile`, `catalog`, `cart`, `wishlist`, `order`, `notification`, `health`. Each has `controller/`, `service/`, `mapper/`, `payload/`.
- **Entities, persisted enums and repositories live in `shared/`** (`shared.domain`, `shared.enums`, `shared.repository`) because several slices use them; request/response payloads belong to exactly one slice and are never reused across slices. Entities never appear in controller signatures or JSON; payloads never appear in repository signatures. `shared` must not depend on any slice.
- **Response envelope:** every response (success or failure) is `ApiResponse<T>` = `{status, data, common{requestId, apiId, timestamp}, error}`. Controllers return through shared `ok`/`created` helpers from `BaseController`, never pick HTTP statuses themselves, and empty success is HTTP 200 with `data: {}` (not 204). Each handler carries exactly one `@ApiId("XXX-NNNN")` that must match `docs/api-specification.md`.
- **Errors:** services throw `BusinessException(StatusCode.X)`; `GlobalExceptionHandler` maps it to the envelope. Security filters write envelope-shaped 401/403 themselves (they run before MVC). Clients resolve user-facing text from the error `code`, not `message`.
- **Ownership:** cart, wishlist, order and notification queries are scoped by the authenticated owner inside the query itself; the current user comes from the security context, never a request field.
- **Auth:** stateless RSA-signed JWT, 15-min access / 7-day refresh. Refresh issues a new pair without invalidating older unexpired ones; logout invalidates all tokens via a per-user token version.
- **Orders:** placement is a single transaction (lock stock in product-id order, revalidate, snapshot items/delivery/totals, decrement stock, clear cart, create the order notification). `Idempotency-Key` is required; a replay returns the original order, changed input returns `CONFLICT`. The server computes all totals; v1 delivery is a flat USD 4.00 and cash on delivery is the only payment method.
- Money is a decimal string plus `currency` on the wire; internal ids are `Long`, public ids are UUIDs.

## Database and tests

- Schema is owned by Flyway (`src/main/resources/db/migration`, V1–V8); Hibernate only validates (`ddl-auto: validate`). Add a new `V<n>__*.sql` migration for any schema change — never edit an applied one.
- **Tests do not use PostgreSQL or Flyway.** The `test` profile uses in-memory H2 in PostgreSQL mode with `ddl-auto: create-drop` and Flyway disabled, so a migration mistake will not fail the suite. Verify migrations against a real Postgres.
- Tests are `@SpringBootTest` + `@AutoConfigureMockMvc` + `@ActiveProfiles("test")` and assert on the envelope (`$.common.apiId`, `$.data…`). Each class is named `<Feature>ApiTest` and cleans its tables in `@BeforeEach`.
- Jackson is configured to reject unknown request properties.

## Gotchas

- `docs/backend/backend-patterns.md` and the blueprint name the base package `com.mercato.api` and artifact `mercato-api`; the actual code uses `com.setec.ecommerce` and `ecommerce-api`. Follow the code.
- Deferred in v1 (do not build): Settings/About/Contact screens, password-reset completion and email delivery, card payments, push notifications, guest cart/wishlist merging, order cancellation/returns, tax and discounts. The prototype shows some of these as "Coming soon" or disabled.
- The prototype lets guests add to cart/wishlist; the requirements say cart, wishlist, checkout, orders, profile and notifications require sign-in. Implement the requirement in Flutter.
