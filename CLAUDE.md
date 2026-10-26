# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

APM (All Products Marketplace, formerly "Mercato") is a mobile e-commerce app (Setec Institute year-4 project), split into three parts:

- `backend/` — Spring Boot 4 / Java 21 REST API (`com.setec.ecommerce`). **All v1 endpoints are implemented and tested.**
- `frontend-app/` — Flutter app (Android/iOS phones, portrait), all screens built from the prototype and connected to the backend API. See **Flutter app status** below.
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
cp .env.example .env                                      # once: set DATABASE_PASSWORD (API runs on port 8081; change SERVER_PORT if taken)
./gradlew bootRun                                         # needs PostgreSQL; reads backend/.env
```

Config comes from env vars or `backend/.env` (git-ignored, imported via `spring.config.import`; real env vars win) — see `backend/.env.example`: `SPRING_PROFILES_ACTIVE`, `DATABASE_URL`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`; also `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY`, `CORS_ALLOWED_ORIGINS`, `SERVER_PORT`). The `dev` profile (default) falls back to `postgresql://localhost:5432/e-commerce`. Swagger UI is at `/swagger-ui.html`.

## Frontend commands

Run from `frontend-app/`:

```bash
flutter pub get
flutter analyze                                   # must report "No issues found!"
flutter test                                      # all unit + widget tests
flutter test test/screens/auth_screens_test.dart  # one file
flutter test test/api/live_api_test.dart --dart-define=LIVE_API=true   # smoke test against a running backend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081/api/v1    # API address (default http://localhost:8081/api/v1)
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

All 15 screens are built from the prototype and connected to the Spring backend, in these reviewed slices:

| API slice | Scope | Status |
|---|---|---|
| A | Foundation: `ApiClient` (dio), envelope + error codes, secure token storage, refresh on 401, health, dev catalog seed | Done |
| B | Auth + profile (login, register, logout, forgot password, `/auth/me`, `PATCH /me/profile`); drop the mock demo account | Done |
| C | Catalog: categories, server-side search/sort/filter, paging, product details | Done |
| D | Cart + wishlist on the server (cart items have their own `itemId`) | Done |
| E | Orders (preview, place with `Idempotency-Key`, history) + notifications | Done |

Proposed next slices (not started; the user reviews and picks one):

| Slice | Scope | Status |
|---|---|---|
| F | Fewer requests on Home: add the unread count and the active order to `GET /auth/me`, so login sends 4 requests instead of 6 (backend change) | Proposed |
| G | Real-device check: run the screenshot test on the iPhone 16 simulator against the backend; check every screen, error and offline state, and the Android `10.0.2.2` address | Proposed |
| H | Polish and release prep: app name and icon check, a release build, clean up old "Mercato" names in docs and the prototype (the root `README.md` is already written) | Proposed |
| I | Optional: place one real order on the dev database with the live test (`--dart-define=LIVE_ORDER=true`). Irreversible, so only when the user says so | Proposed |

Known API differences to handle: register takes no phone (send it via `PATCH /me/profile`), `DELETE /notifications` has no undo, lists are paginated, money is `{amount: "89.00", currency}`, badges arrive lowercase and unordered (use `Product.cardBadge` / `badgesInOrder`).

How the API is used (details in each provider):
- **Catalog (C):** Home reads categories plus two small product sections (`ensureHome()`); related products and product details are their own requests (`loadRelated`, `ensureProduct`). The Categories screen searches on the server (`showCategory`, `updateFilter` with a 300 ms typing pause, `loadMoreResults` while scrolling); product details call `loadProduct`. Catalog reads are public (`auth: false`).
- **Cart + wishlist (D):** every cart change returns the whole cart, so totals and stock rules are the server's (a line's stepper is disabled while its change is in flight; stock errors become toasts). `CartItem.id` is the cart line, `productId` the product. The wishlist holds full products, newest first; hearts change at once and roll back with a message on failure; Undo saves again.
- **Orders + notifications (E):** checkout shows `POST /orders/preview` totals and places with `POST /orders` + `Idempotency-Key` (one key per set of delivery details: a retry can never duplicate; changed details get a new key). The server empties the ordered items from the cart and creates an "Order placed" notification, so both reload afterwards. Order history is `OrderSummary` pages (no item lines or photos); details are `Order` via `loadOrder` (item photos come from the catalog). Notifications are paged with a server unread count; "Clear all" asks first because the server can't undo it. References look like `MC-1A2B3C4D5E6F`.
- Nothing is mock data any more: `lib/data/` is gone. Only the guest flag lives in `shared_preferences`.
- **Lazy loading:** signing in loads only the profile (`GET /auth/me`, whose `counts` drive the cart badge and Profile numbers). Each screen loads what it shows only while it is on screen (`utils/on_screen.dart` `loadWhenOnScreen` — background tabs kept alive by the shell never fetch; `ensureLoaded()` from `FollowsSignIn`, `ProductProvider.ensureHome()`), so Home requests only its catalog sections, the active-order banner and the unread count. Cart, wishlist, orders and notifications load on their own screens.
- **Paging:** every list request uses `ApiConfig.pageSize` (20) and loads the next page while scrolling; section sizes (`homeSectionSize`, `relatedSize`) also live in `ApiConfig`. Never request a list all at once.
- **Hearts** use `Product.saved` from the catalog (sent when the request carries a token) plus hearts tapped this session (`WishlistProvider.isSaved`), so the wishlist is never downloaded just to draw hearts. Signing in/out requests nothing: catalog data is marked out of date and each screen re-reads it when next shown.
- **Tokens** are refreshed shortly before the access token expires (`exp` read from the JWT), and once more on a 401.

## Flutter architecture (full spec: `docs/frontend/flutter-structure.md`)

- **Beginner structure, grouped by type:** `models/`, `services/`, `providers/` are each split into the same areas (auth, product, cart, order, wishlist, notification, user); `screens/<screen>/<screen>_screen.dart` with an optional `widgets/` subfolder for screen-only widgets; shared widgets in `widgets/{layout,buttons,inputs,cards,feedback}`; `theme.dart` (all colours/text/spacing tokens — use `AppColors`, `AppText`, `AppSpacing`, never raw values), `router.dart`, `utils/`.
- **Data flow:** screen → `context.watch/read<XProvider>()` → provider (`ChangeNotifier`, holds `isLoading`/`error`) → service (every method returns a `Future` and calls the API through `ApiClient`). Screens never call services directly.
- **API layer (`services/api/`):** one shared `ApiClient.instance` (dio) sends the bearer token, unwraps the `ApiResponse` envelope, refreshes tokens once on a 401 and retries, and throws `ApiException`. Show `e.userMessage` (mapped from the error `code`), never the server's message. Tokens live in `flutter_secure_storage`. Being offline never signs the user out.
- **Navigation (go_router):** `StatefulShellRoute` with 5 tabs (Home, Categories, Wishlist, Cart, Profile) rendered by `widgets/layout/main_shell.dart`; `/notifications` lives in the Home branch and `/orders`, `/orders/:id` in the Profile branch (tab bar stays visible). Full screen: splash, auth, `/product/:id`, `/checkout`, `/orders/:id/confirmed`. A redirect sends guests to `/login?from=…` for cart, wishlist, checkout, orders, profile and notifications.
- **Assets:** only images the API never sends are bundled — Manrope font, Home banner photos (`assets/images/banners/`), logo/category icons/placeholder as SVG (`assets/icons/`, via `flutter_svg`). Product photos stay as URLs (`imageUrl`). UI icons use Material icons.
- **Brand:** APM — All Products Marketplace (green/white). Logo mark `assets/icons/logo_mark.svg` (shown by `widgets/layout/brand_logo.dart`; the prototype uses a copy in `docs/prototype/assets/logo-mark.svg`). Launcher icons are generated from `branding/app_icon.svg` with `python tool/generate_icons.py` (needs Chrome + Pillow) — don't edit the PNGs by hand.
- **Auth:** email + password only through the API — no Google/Apple sign-in. Signed in = tokens in secure storage; "Continue as guest" is a local flag. `UserProvider` follows `AuthProvider` (ProxyProvider in `main.dart`): profile loads from `GET /auth/me` after sign-in and clears after sign-out. A failed token refresh signs out and Sign in shows "Your session has ended". Debug builds offer the backend dev account (`services/auth/dev_account.dart`, from `V2__seed_users.sql`) as "Fill in".
- **Widget tests use a fake backend** (`test/fake_api.dart` + the sample catalog in `test/fake_catalog.dart`, set up by `startAppAtLogin` in `test/helpers.dart`) that mimics every endpoint the app calls, so they never need the server. Its dev account starts with a cart, wishlist, 2 orders and 4 notifications. The simulator screenshot test (`integration_test/`) uses the real API, so start the backend first.
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
- Dev-only sample data lives in `src/main/resources/db/dev/` (repeatable `R__dev_seed_catalog.sql`: the 4 categories and 6 products the Flutter app uses), loaded only by the `dev` profile. Dev sign-in is the account seeded by `V2__seed_users.sql`.
- **Tests do not use PostgreSQL or Flyway.** The `test` profile uses in-memory H2 in PostgreSQL mode with `ddl-auto: create-drop` and Flyway disabled, so a migration mistake will not fail the suite. Verify migrations against a real Postgres.
- Tests are `@SpringBootTest` + `@AutoConfigureMockMvc` + `@ActiveProfiles("test")` and assert on the envelope (`$.common.apiId`, `$.data…`). Each class is named `<Feature>ApiTest` and cleans its tables in `@BeforeEach`.
- Jackson is configured to reject unknown request properties.

## Gotchas

- `docs/backend/backend-patterns.md` and the blueprint name the base package `com.mercato.api` and artifact `mercato-api`; the actual code uses `com.setec.ecommerce` and `ecommerce-api`. Follow the code.
- Deferred in v1 (do not build): Settings/About/Contact screens, password-reset completion and email delivery, card payments, push notifications, guest cart/wishlist merging, order cancellation/returns, tax and discounts. The prototype shows some of these as "Coming soon" or disabled.
- The prototype lets guests add to cart/wishlist; the requirements say cart, wishlist, checkout, orders, profile and notifications require sign-in. Implement the requirement in Flutter.
