# Flutter app structure

How the APM (All Products Marketplace) Flutter app in `frontend-app/` is organised. The screens are built from the approved HTML prototype in [`docs/prototype/`](prototype/README.md).

## 1. Decisions

| Topic | Decision |
|---|---|
| State management | [`provider`](https://pub.dev/packages/provider) — one `ChangeNotifier` per area |
| Navigation | [`go_router`](https://pub.dev/packages/go_router) |
| Data | From the Spring API. Services return `Future`s; screens only talk to providers. |
| Saving on the device | [`shared_preferences`](https://pub.dev/packages/shared_preferences) only for the "continue as guest" flag; everything else lives on the server |
| Font | Manrope, bundled in `assets/fonts/` |
| Images | Product photos come from the API, so they stay as URLs. Images the API never sends are bundled in `assets/`: Home banner photos, the APM logo, category icons and the image placeholder. |
| Vector images | SVG files shown with [`flutter_svg`](https://pub.dev/packages/flutter_svg); other UI icons use Flutter's built-in Material icons |
| API | [`dio`](https://pub.dev/packages/dio) through one shared `ApiClient` (`services/api/`). Tokens in [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage). Screens show `ApiException.userMessage`, never the server's `message`. |
| Sign-in | Email + password only (JWT from the backend) — no Google/Apple sign-in. Guests can browse and search. Cart, wishlist, checkout, orders, profile and notifications require sign-in (see [requirement.md §7.2](requirements.md#project-requirements)). |
| Test device | iOS simulator (iPhone 16) |

## 2. Folder structure

```
frontend-app/
├── pubspec.yaml                       provider, go_router, shared_preferences, intl, flutter_svg
├── assets/                            only images the API doesn't send
│   ├── fonts/                         Manrope font files + OFL.txt licence
│   ├── images/
│   │   ├── CREDITS.md                 photo credits (Unsplash)
│   │   └── banners/                   Home carousel photos
│   └── icons/                         logo_mark.svg (APM logo), leaf.svg, category_*.svg, image_placeholder.svg
├── branding/app_icon.svg              launcher icon source; `python tool/generate_icons.py` writes the iOS/Android/web icons
└── lib/
    ├── main.dart                      starts the app: providers + theme + router
    ├── router.dart                    every screen path (/home, /cart, /product/:id …)
    ├── theme.dart                     colours, fonts, button and input styles
    │
    ├── models/                        plain data classes
    │   ├── product/
    │   │   ├── product.dart
    │   │   ├── category.dart
    │   │   └── product_filter.dart    search text, sort, in-stock-only (Categories)
    │   ├── cart/
    │   │   ├── cart.dart              the server's cart: items, subtotal, item count
    │   │   └── cart_item.dart         one cart line (its own id + the product id)
    │   ├── order/
    │   │   ├── order.dart
    │   │   └── order_item.dart
    │   ├── notification/
    │   │   └── app_notification.dart
    │   ├── user/
    │   │   └── user.dart
    │   └── common/
    │       └── page_result.dart       one page of a paginated API list (items, page, hasNext)
    │
    ├── services/                      fetch and save data (return Future)
    │   ├── api/                       shared by every service that calls the Spring API
    │   │   ├── api_config.dart        base URL (--dart-define=API_BASE_URL=…), timeouts
    │   │   ├── api_client.dart        requests, envelope, bearer token, refresh on 401
    │   │   ├── api_exception.dart     error code → user-facing message
    │   │   └── token_storage.dart     access/refresh tokens in the Keychain / Keystore
    │   ├── health/health_service.dart GET /health
    │   ├── auth/
    │   │   ├── auth_service.dart      login, register (+ phone via profile), logout, change password
    │   │   └── dev_account.dart       backend dev account (used by tests)
    │   ├── product/product_service.dart
    │   ├── cart/cart_service.dart
    │   ├── order/order_service.dart
    │   ├── wishlist/wishlist_service.dart
    │   ├── notification/notification_service.dart
    │   └── user/user_service.dart     GET /auth/me, PATCH /me/profile
    │
    ├── providers/                     app state that screens listen to
    │   ├── auth/auth_provider.dart
    │   ├── product/product_provider.dart
    │   ├── cart/cart_provider.dart
    │   ├── order/order_provider.dart
    │   ├── wishlist/wishlist_provider.dart
    │   ├── notification/notification_provider.dart
    │   └── user/user_provider.dart
    │
    ├── screens/                       one folder per screen
    │   ├── splash/splash_screen.dart
    │   ├── login/login_screen.dart
    │   ├── register/
    │   │   ├── register_screen.dart
    │   │   └── widgets/password_strength.dart
    │   ├── home/
    │   │   ├── home_screen.dart
    │   │   └── widgets/hero_banner.dart
    │   ├── categories/
    │   │   ├── categories_screen.dart
    │   │   └── widgets/filter_sheet.dart
    │   ├── product_detail/product_detail_screen.dart
    │   ├── cart/
    │   │   ├── cart_screen.dart
    │   │   └── widgets/cart_item_tile.dart
    │   ├── checkout/
    │   │   ├── checkout_screen.dart
    │   │   └── widgets/delivery_details.dart
    │   ├── order_confirmed/order_confirmed_screen.dart
    │   ├── orders/
    │   │   ├── orders_screen.dart
    │   │   └── widgets/order_card.dart
    │   ├── order_detail/
    │   │   ├── order_detail_screen.dart
    │   │   └── widgets/order_status_timeline.dart
    │   ├── wishlist/wishlist_screen.dart
    │   ├── notifications/
    │   │   ├── notifications_screen.dart
    │   │   └── widgets/notification_tile.dart
    │   └── profile/
    │       ├── profile_screen.dart
    │       └── widgets/edit_profile_sheet.dart
    │
    ├── widgets/                       shared pieces used by two or more screens
    │   ├── layout/
    │   │   ├── main_shell.dart            frame for the 5 tabs (screen + floating tab bar), used by router.dart
    │   │   ├── brand_logo.dart            APM logo mark + name
    │   │   ├── auth_layout.dart           frame for Sign in / Create account / Reset password
    │   │   ├── app_header.dart            back button + centred title + action
    │   │   ├── section_header.dart        section title + optional "See all"
    │   │   ├── bottom_nav_bar.dart        floating tab bar with cart badge
    │   │   └── action_dock.dart           sticky bottom bar (Add to cart, Checkout, Place order)
    │   ├── buttons/
    │   │   ├── app_button.dart            primary / secondary / outline / danger
    │   │   └── circle_icon_button.dart    round back, heart, filter buttons
    │   ├── inputs/
    │   │   ├── app_text_field.dart        label, inline error, show/hide password
    │   │   ├── search_bar.dart
    │   │   ├── category_chip.dart         pill chip for categories/filters (+ category icon lookup)
    │   │   └── quantity_stepper.dart
    │   ├── cards/
    │   │   ├── product_image.dart         product photo (URL) with placeholder while loading
    │   │   ├── app_card.dart              white card (or mint tint) used for summaries
    │   │   ├── price_summary.dart         subtotal / delivery / total rows (cart, checkout, order)
    │   │   ├── product_card.dart          grid card (image, Add, heart)
    │   │   ├── product_grid.dart          2-column grid of product cards with cart/wishlist actions
    │   │   ├── product_list_card.dart     horizontal card (wishlist, new arrivals)
    │   │   └── link_banner.dart           tappable strip (order update, "already in your cart")
    │   └── feedback/
    │       ├── alert_banner.dart          inline success / error / info message
    │       ├── empty_state.dart
    │       ├── loading_skeleton.dart
    │       ├── status_badge.dart
    │       ├── order_status_badge.dart    Pending / Confirmed / Shipped / Delivered pill
    │       ├── app_bottom_sheet.dart
    │       ├── confirm_dialog.dart        "Are you sure?" popup (log out, reset, discard edits)
    │       └── app_toast.dart             snackbar with Undo / View cart
    │
    └── utils/
        ├── formatters.dart            $89.00, "2 hours ago"
        ├── validators.dart            email, phone, password checks
        └── product_actions.dart       add to cart / save to wishlist + toast (asks guests to sign in)
```

## 3. Where does a file go?

| You are adding… | Put it in |
|---|---|
| A data class (product, order, …) | `models/<area>/` |
| Code that loads or saves data | `services/<area>/` |
| State a screen needs (lists, totals, loading, errors) | `providers/<area>/` |
| A new screen | `screens/<screen_name>/<screen_name>_screen.dart` |
| A widget used by **one** screen | `screens/<screen_name>/widgets/` |
| A widget used by **two or more** screens | `widgets/<kind>/` (layout, buttons, inputs, cards, feedback) |
| Formatting or validation helpers | `utils/` |

The seven areas are the same everywhere: **auth, product, cart, order, wishlist, notification, user**. So `CartScreen` uses `providers/cart/cart_provider.dart`, which uses `services/cart/cart_service.dart`, which uses `models/cart/cart_item.dart`.

## 4. How the layers work together

```
Screen  ──reads/calls──▶  Provider  ──awaits──▶  Service  ──▶  ApiClient  ──▶  Spring API
   ▲                          │
   └──── notifyListeners() ───┘   (every screen showing that data rebuilds)
```

- **Service:** fetches and saves data. It holds no state and knows nothing about the UI. Every function returns a `Future`.
- **Provider:** keeps the current state (`items`, `isLoading`, `error`), calls services, and calls `notifyListeners()` after changes.
- **Screen:** reads the provider with `context.watch<…>()` and calls its methods on taps. It doesn't call services directly.

Example, with the same pattern for every area:

```dart
// services/product/product_service.dart
class ProductService {
  Future<List<Product>> getProducts() async {
    final data = await ApiClient.instance.get('/products', auth: false);
    return PageResult.fromJson(data, Product.fromJson).items;
  }
}

// providers/product/product_provider.dart
class ProductProvider extends ChangeNotifier {
  final _service = ProductService();
  List<Product> products = [];
  bool isLoading = false;
  String? error;

  Future<void> loadProducts() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      products = await _service.getProducts();
    } catch (e) {
      error = 'Could not load products';
    }
    isLoading = false;
    notifyListeners();
  }
}

// screens/home/home_screen.dart (inside build)
final p = context.watch<ProductProvider>();
if (p.isLoading) return const LoadingSkeleton();
if (p.error != null) return EmptyState(title: p.error!, actionLabel: 'Try again', onAction: p.loadProducts);
return ProductGrid(products: p.products);
```

Connecting the real backend later only means changing the service files. Providers and screens stay the same.

## 5. Screens and routes

🔒 = requires sign-in (guests are sent to `/login`).

| Route | Screen file | Providers used | Prototype |
|---|---|---|---|
| `/splash` | `splash/splash_screen.dart` | auth | `splash.html` |
| `/login` | `login/login_screen.dart` | auth | `login.html` |
| `/register` | `register/register_screen.dart` | auth | `register.html` |
| `/home` (tab) | `home/home_screen.dart` | product, cart, wishlist, order | `home.html` |
| `/categories` (tab) | `categories/categories_screen.dart` | product, cart, wishlist | `categories.html` |
| `/product/:id` | `product_detail/product_detail_screen.dart` | product, cart, wishlist | `product.html` |
| `/cart` (tab) 🔒 | `cart/cart_screen.dart` | cart, wishlist | `cart.html` |
| `/checkout` 🔒 | `checkout/checkout_screen.dart` | cart, order, user | `checkout.html` |
| `/orders/:id/confirmed` 🔒 | `order_confirmed/order_confirmed_screen.dart` | order | `order-confirmed.html` |
| `/orders` 🔒 | `orders/orders_screen.dart` | order | `orders.html` |
| `/orders/:id` 🔒 | `order_detail/order_detail_screen.dart` | order | `order-detail.html` |
| `/wishlist` (tab) 🔒 | `wishlist/wishlist_screen.dart` | wishlist, cart | `wishlist.html` |
| `/notifications` 🔒 | `notifications/notifications_screen.dart` | notification, order | `notifications.html` |
| `/profile` (tab) 🔒 | `profile/profile_screen.dart` | user, auth, order | `profile.html` |

The bottom tab bar shows **Home, Categories, Wishlist, Cart, Profile**. Product details, checkout and order confirmation open full screen without the tab bar.

## 6. Tests and review screenshots

```
frontend-app/
├── test/                              unit + widget tests (flutter test)
│   ├── helpers.dart                   phone-sized screen, wait/tap helpers, app start against the fake backend
│   ├── fake_api.dart                  in-memory fake of every API endpoint the app calls
│   ├── fake_catalog.dart              the sample categories and products the fake serves
│   ├── api/                           ApiClient tests + live tests against a running backend (opt-in)
│   ├── app_test.dart                  splash → sign in → guest → cart redirect
│   ├── providers/                     provider rules (cart totals, stock limits, saving)
│   ├── screens/                       screen behaviour (validation, messages)
│   └── utils/                         validators and formatters
├── integration_test/
│   └── review_screenshots_test.dart   taps through finished screens on the simulator
└── test_driver/
    └── integration_test.dart          saves those screenshots to build/screenshots/
```

```bash
flutter test                           # all unit + widget tests
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/review_screenshots_test.dart -d "iPhone 16"   # review screenshots
```

## 7. Build order

Each slice is reviewed before the next one starts.

1. **Foundation:** `theme.dart`, `router.dart`, shared `widgets/`, models, `mock_data.dart`, services and providers.
2. **Auth:** splash, login, register, forgot password.
3. **Shopping:** home, categories (search, filter, sort), product detail.
4. **Buying:** cart, checkout, order confirmed, orders, order detail.
5. **Account:** wishlist, notifications, profile (edit sheet, log out).
