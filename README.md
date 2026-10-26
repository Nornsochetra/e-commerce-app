# APM — All Products Marketplace

A mobile e-commerce app (Setec Institute year-4 project). Customers browse a catalog, keep a cart and
a wishlist, place cash-on-delivery orders and follow them through notifications.

| Part | What it is |
|---|---|
| [`backend/`](backend/) | REST API: Spring Boot 4, Java 21, PostgreSQL (schema by Flyway), JWT sign-in |
| [`frontend-app/`](frontend-app/) | Flutter app for Android and iOS phones (Provider + go_router), connected to the API |
| [`docs/`](docs/) | Requirements, use cases, feature specs, API specification, data model, and the clickable HTML prototype |

## Requirements

- Java 21 (the Gradle wrapper downloads Gradle itself)
- PostgreSQL with an empty database named `e-commerce`
- Flutter SDK (Dart 3.12 or newer), plus Xcode for iOS or Android Studio for Android

## Run the backend

```bash
cd backend
cp .env.example .env      # once: set DATABASE_PASSWORD to your PostgreSQL password
./gradlew bootRun
```

- The API runs at `http://localhost:8081/api/v1`. If port 8081 is taken, change `SERVER_PORT` in `.env`.
- Flyway creates the tables on first start. The `dev` profile (the default) also loads sample
  categories and products.
- API docs: `http://localhost:8081/swagger-ui.html`.
- `.env` holds your database password and is git-ignored. Never commit it.

Other settings (all optional in `dev`): `DATABASE_URL`, `DATABASE_USERNAME`, `RSA_PUBLIC_KEY` /
`RSA_PRIVATE_KEY` (token signing keys), `CORS_ALLOWED_ORIGINS`.

## Run the app

Start the backend first, then:

```bash
cd frontend-app
flutter pub get
flutter run -d "iPhone 16"          # iOS simulator (the agreed test device)
```

The app calls `http://localhost:8081/api/v1` by default. On the Android emulator, `localhost` is the
emulator itself, so pass the host address instead:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081/api/v1
```

**Signing in:** debug builds show a **Fill in** button on the Sign in screen with the development
account seeded by the backend (`user@example.com` / `Demo123!`). You can also create an account, or
continue as a guest to browse.

## Tests

```bash
# Backend: in-memory H2, no PostgreSQL needed
cd backend
./gradlew test
./gradlew spotlessCheck             # formatting (spotlessApply fixes it)

# App: a fake backend inside the tests, no server needed
cd frontend-app
flutter analyze                     # must report "No issues found!"
flutter test

# App against a running backend
flutter test test/api/live_api_test.dart --dart-define=LIVE_API=true
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/review_screenshots_test.dart -d "iPhone 16"   # screenshots → build/screenshots/
```

The live test skips placing an order unless you add `--dart-define=LIVE_ORDER=true`. That order is
real and stays in the database.

## Prototype

Open `docs/prototype/index.html` in a browser. No build step or server is needed. It is the visual
spec for the app screens; `docs/prototype/screens.html` lists every screen.

## What v1 does not include

Card payments (cash on delivery only), password-reset emails, push notifications, order
cancellation and returns, tax and discounts, and Settings/About/Contact screens.
