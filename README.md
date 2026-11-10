# NestMart – Android app (Flutter)

The Android version of the NestMart supermarket web app, built with Flutter so the same code can later target iOS.
It follows the web app's phone layout, colours, fonts, icons, texts and behaviour screen by screen.

## Requirements

- **Flutter 3.47 or newer** (Dart 3.13+). Check with `flutter --version`; update with `flutter upgrade`.
  The app uses the standalone `material_ui` package that first shipped in Flutter 3.47.
- Android Studio (or the Android SDK command-line tools) with an emulator or a phone.
- Accept the Android licences once: `flutter doctor --android-licenses`

## Run it

```
flutter pub get
flutter run
```

Open the folder in Android Studio or VS Code and press Run, or use `flutter build apk` for an APK.

## What is in the app

Every screen of the web app:

| Area | Screens |
|---|---|
| Shop | Home (hero, deals, popular, new arrivals ...), Shop with search, filters, sorting, grid / list and Load more, Product page (photos, reviews, related products), Wishlist |
| Buying | Cart page and the cart that slides up from "View cart", promo codes, Checkout (delivery slots, express, payment), Order confirmation with live tracking, My orders with Reorder, Track order |
| Account | Account page (profile banner, tiles, Preferences), sign-in, Profile, Address, Customer Support with FAQ, Coupons, Notifications, Contact Us, Privacy Policy, Terms & Conditions, About Us, Photo credits |
| Everywhere | Search with suggestions, city and category sheets, Dark Mode switch, 5 colour themes (light and dark), English / Bengali / Arabic (right-to-left), toasts, bottom bar |

## Where the data comes from

The web app has no server: its catalogue is a JavaScript file and everything the visitor does (cart, wishlist, orders,
theme, language) is kept in the browser. The Android app does the same:

- `assets/data/catalogue.json` – the web app's catalogue (4 departments, 30 categories, 192 products) and its store settings
  (name, currency, delivery fees, cities, promo codes ...).
- `assets/data/translations.json` – the web app's Bengali and Arabic dictionary.
- Cart, wishlist, orders, account, theme and language are saved on the phone with `shared_preferences`, in the same JSON
  shape the web app keeps under the `freshnest.v1` key.

So orders are **not sent anywhere yet**. When a real backend is chosen, only the data layer (`lib/data`,
`lib/state/store.dart`) changes; the screens stay as they are.

## Project layout

```
lib/
  main.dart, app.dart        start-up, theme, language, routes
  app_routes.dart            which screen each route opens
  core/                      design tokens (colours of the 5 palettes, light + dark), theme, config, formatting,
                             languages + translator, navigation helper, external links
  data/                      models, catalogue loader, product search
  state/                     cart / wishlist / orders / theme state (Riverpod), toasts, shop actions, reviews
  shell/                     the frame around every page: announcement strip, header, search, bottom bar, footer, sheets
  widgets/                   icons, buttons, forms, product card, product picture, cart parts ...
  screens/                   home, shop (+ product), cart (+ checkout), orders, account, info pages
assets/                      product photos, logo, fonts, catalogue / translations / credits JSON
test/                        layout and behaviour tests (see below)
```

## Tests

`flutter test` renders the whole app without a device - every screen, in every language, several colour themes, light and
dark, and phone sizes from 320 to 600dp wide - scrolls each page and fails on any overflow or layout error. It also runs the
real flows: search, filters, adding to the cart, promo codes, checkout and placing an order, reviews, sign-in, forms,
coupons, notifications and the translator.

## Notes

- Application ID: `com.nestmart.supermarket` (change it in `android/app/build.gradle.kts` before the first Google Play upload).
- The app stays in portrait, like the phone layout of the web app.
- The app needs no internet permission today (nothing is fetched). Add `android.permission.INTERNET` when a backend is connected.
- Regenerate the launcher icon after changing `assets/icons/icon-512.png`: `dart run flutter_launcher_icons`
