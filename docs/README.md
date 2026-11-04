# APM documentation

Everything about how APM (All Products Marketplace) should work. Read the file for the part you are
changing, and update it in the same change.

Read them in this order:

| # | File | What it tells you |
|---|---|---|
| 1 | [requirements.md](requirements.md) | What the app must do, the list of screens, and how people use it (use cases) |
| 2 | [features.md](features.md) | Each feature in detail: sign-in, profile, catalog, cart, wishlist, orders, notifications |
| 3 | [api.md](api.md) | How the app talks to the server: the rules, then every endpoint |
| 4 | [database.md](database.md) | The tables, with the [ERD](images/erd.png) |
| 5 | [backend.md](backend.md) | How the Spring Boot code is organised |
| 6 | [flutter.md](flutter.md) | How the Flutter app is organised |

Also here:

- [`prototype/`](prototype/README.md): the clickable HTML design of every screen. Open
  `prototype/index.html` in a browser.
- [`images/`](images/): pictures used by these docs.

Good to know:

- `backend.md` still names the package `com.mercato.api`; the code uses `com.setec.ecommerce`.
  Follow the code.
- The prototype still shows a few things the app no longer has: the Forgot password screen, the
  Settings/About/Contact rows on Profile and the card payment option at checkout. `requirements.md`
  decides what is built.
