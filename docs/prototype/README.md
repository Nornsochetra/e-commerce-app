# APM UI prototype

Clickable mobile prototype of the APM (All Products Marketplace) app. **One screen = one HTML file.** Each file loads React, Babel and Tailwind from a CDN, plus the two shared assets. There is no build step and no Node.js.

**Open it:** double-click `index.html`, which opens the splash screen (`splash.html`). Works straight from `file://`; an internet connection is needed for the CDNs, font and product photos. `screens.html` lists every screen.

Demo sign-in: `demo@apm.app` / `Demo123!`. Data is mock data kept in the browser's `localStorage`. Use Profile → **Reset demo data** to start over.

## Structure

```
prototype/
├── assets/
│   ├── mercato.css        design tokens + component styles (buttons, cards, tab bar, sheets…)
│   └── mercato.js         shared runtime, plain JS (no JSX):
│                            • Mercato.*  mock data, cart/wishlist/orders helpers, toasts
│                            • Mercato.to links to screen files, Mercato.mount(Screen)
│                            • shared components as globals: ScreenLayout, AppHeader, TabBar,
│                              ProductCard, ListCard, QtyStepper, BottomSheet, TextField, …
├── index.html             Entry point — redirects to splash.html
├── splash.html            Splash → login.html or home.html
├── login.html             Sign in
├── register.html          Create account
├── forgot-password.html   Reset password
├── home.html              Home                       (tab: Home)
├── categories.html        Categories, search, filters (tab: Categories)  ?category=<slug>&focus=search&filters=open
├── product.html           Product details            ?id=<productId>
├── cart.html              Shopping cart              (tab: Cart)
├── checkout.html          Checkout
├── order-confirmed.html   Order confirmation         ?id=<orderId>
├── orders.html            Order history (from Profile)
├── order-detail.html      Order details              ?id=<orderId>
├── wishlist.html          Wishlist                   (tab: Wishlist)
├── notifications.html     Notifications (bell icon)
├── profile.html           Profile + edit sheet       (tab: Profile)
└── screens.html           Index of every screen, for reviewers
```

## How navigation works

- Screens link to each other with normal links: `<a href={Mercato.to.cart}>` opens `cart.html`, and `Mercato.to.product(id)` gives `product.html?id=…`.
- In code, use `navigate(href)` or `navigate(href, { replace: true })`. `goBack(fallbackHref)` returns to the previous screen, or opens the fallback when the screen was opened directly.
- The floating tab bar comes from `<ScreenLayout active="home|shop|wishlist|cart|profile">`. Pass `nav={false}` to hide it, as on product details and checkout.

## Adding a screen

Copy this into `settings.html`, add the link in `Mercato.to` (in `assets/mercato.js`) if other screens need it, and list it in `screens.html`.

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
  <title>APM — Settings</title>
  <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet">
  <link rel="stylesheet" href="assets/mercato.css" />
  <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4.1.11"></script>
  <script crossorigin src="https://unpkg.com/react@18.3.1/umd/react.production.min.js"></script>
  <script crossorigin src="https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js"></script>
  <script src="https://unpkg.com/@babel/standalone@7.24.7/babel.min.js"></script>
  <script src="assets/mercato.js"></script>
</head>
<body>
<div id="root"></div>
<script type="text/babel">
function SettingsScreen({ goBack }) {
  return <ScreenLayout active="profile" header={<AppHeader title="Settings" onBack={() => goBack(Mercato.to.profile)} />}>
    <section className="card">
      <p className="t-body">Settings content goes here.</p>
      <a href={Mercato.to.home} className="btn btn-primary btn-block mt-4">Back to shopping</a>
    </section>
  </ScreenLayout>;
}

Mercato.mount(SettingsScreen);
</script>
</body>
</html>
```

`Mercato.mount(Screen)` renders the screen, re-renders it whenever cart, wishlist or other data changes, and passes `params`/`query` (this page's URL query), `navigate` and `goBack`.
