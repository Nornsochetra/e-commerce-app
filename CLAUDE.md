# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

Mercato is a mobile e-commerce app (Setec Institute year-4 project), split into three parts:

- `backend/` — Spring Boot 4 / Java 21 REST API (`com.setec.ecommerce`). **All v1 endpoints are implemented and tested.**
- `frontend-app/` — Flutter app (Android/iOS phones, portrait), all screens built from the prototype with mock data (not yet connected to the backend). See **Flutter app status** below.
- `docs/` — the source of truth for behavior. Read the relevant doc before changing a feature.
  - `requirement.md` (scope, screen inventory SCR-001…022, system-wide business rules), `usecase.md`, `features/*.md` (per-feature specs), `api-convention.md`, `api-specification.md` (every endpoint, keyed by ApiId), `data-model.md`, `backend/backend-patterns.md`, `frontend/flutter-structure.md` (agreed Flutter folder structure, Provider + go_router, build order).
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

Run from `frontend-app/`:

```bash
flutter pub get
flutter analyze                                   # must report "No issues found!"
flutter test                                      # all unit + widget tests
flutter test test/screens/auth_screens_test.dart  # one file
flutter run -d "iPhone 16"                        # iOS simulator is the agreed test device
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/review_screenshots_test.dart -d "iPhone 16"   # review screenshots → build/screenshots/
```

## Flutter app status

Built in five slices; the user reviews each slice before the next starts, and commits only when asked.

| Slice | Scope | Status |
|---|---|---|
| 1 | Foundation: theme, models, mock data, services, providers, router, shared widgets, placeholder screens | Done |
| 2 | Splash, Sign in, Create account, Reset password | Done |
| 3 | Home, Categories (search, filter, sort), Product details | Done |
| 4 | Cart, Checkout, Order confirmed, My orders, Order details | Done |
| 5 | Wishlist, Notifications, Profile (edit sheet, log out) | Done |

All 15 screens are built from the prototype. Next step: connect the services to the Spring backend (only `services/` should change).

## Flutter architecture (full spec: `docs/frontend/flutter-structure.md`)

- **Beginner structure, grouped by type:** `models/`, `services/`, `providers/` are each split into the same areas (auth, product, cart, order, wishlist, notification, user); `screens/<screen>/<screen>_screen.dart` with an optional `widgets/` subfolder for screen-only widgets; shared widgets in `widgets/{layout,buttons,inputs,cards,feedback}`; `theme.dart` (all colours/text/spacing tokens — use `AppColors`, `AppText`, `AppSpacing`, never raw values), `router.dart`, `utils/`.
- **Data flow:** screen → `context.watch/read<XProvider>()` → provider (`ChangeNotifier`, holds `isLoading`/`error`) → service (every method returns a `Future`; mock data from `data/mock_data.dart` with a 300 ms delay, saved with `shared_preferences`). Connecting the Spring backend later means changing only the services. Screens never call services directly.
- **Navigation (go_router):** `StatefulShellRoute` with 5 tabs (Home, Categories, Wishlist, Cart, Profile) rendered by `widgets/layout/main_shell.dart`; `/notifications` lives in the Home branch and `/orders`, `/orders/:id` in the Profile branch (tab bar stays visible). Full screen: splash, auth, `/product/:id`, `/checkout`, `/orders/:id/confirmed`. A redirect sends guests to `/login?from=…` for cart, wishlist, checkout, orders, profile and notifications.
- **Assets:** only images the API never sends are bundled — Manrope font, Home banner photos (`assets/images/banners/`), logo/category icons/placeholder as SVG (`assets/icons/`, via `flutter_svg`). Product photos stay as URLs (`imageUrl`). UI icons use Material icons.
- **Auth:** email + password only (demo `demo@mercato.app` / `Demo123!` until the backend is connected) — no Google/Apple sign-in.
- **Tests:** `test/helpers.dart` gives a phone-sized screen and `wait`/`tapVisible` helpers. Use `wait(tester)` instead of `pumpAndSettle` — some animations (splash rings, skeletons) repeat forever.

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
