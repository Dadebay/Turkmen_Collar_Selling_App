# YAKA

YAKA is a Flutter mobile marketplace for Turkmen collar embroidery files and sewing-related products. The app lets customers browse collars, sewing products, machines, and banners; sign in with phone OTP; save favorites; add physical products to a cart; top up an in-app balance; purchase/download collar files; and receive Firebase push notifications.

The Android application ID is `com.gurbanov.yaka`; the iOS bundle ID is `com.bilermennesil.yaka`. The Flutter package name is `yaka2`.

## Download

- [Google Play](https://play.google.com/store/apps/details?id=com.gurbanov.yaka)
- [App Store](https://apps.apple.com/tm/app/%C3%BDaka/id6755652803)
- [GitHub Releases](https://github.com/Dadebay/Turkmen_Collar_Selling_App/releases) — source and verified direct-download files when published. Use the stores until a signed APK is available here.

## Current Version

- Source version: `4.0.4+61` (`pubspec.yaml`); store rollout versions may differ.
- Dart SDK: `>=3.13.0 <4.0.0`; CI uses Flutter 3.47.8 and JDK 17.
- Main platforms: Android and iOS
- Backend base URL: `https://yashelektrik.com`

## Main Features

- Phone number login with OTP verification.
- Home catalog with banners, categories, collars, sewing goods, clothes/new products, and machines.
- Product detail pages with image gallery, price/details, favorites, cart actions, and downloadable collar variants.
- Favorites for collars and regular products.
- Cart and order creation for physical products.
- Wallet/balance display and periodic balance refresh.
- Phone payment and online card payment flows.
- Downloaded collar file history.
- Collar file downloads use the machine-specific mapped folder structure, then optional copy to USB preserves that same structure; iOS saves to app documents.
- User profile/settings, language switch, order history, downloaded files, about page, and account logout/delete action.
- Firebase Cloud Messaging with local notifications and notification deep links.
- Turkmen and Russian localization.
- App update prompt via `upgrader`.

## Tech Stack

- Flutter and Dart.
- flutter_bloc (BLoC pattern) for state management.
- go_router for declarative navigation and deep linking.
- Hive for local persistence (abstracted via `LocalStorage`).
- get_it for dependency injection.
- Firebase Core, Analytics, Messaging, and local notifications.
- Dio/HTTP for REST API calls and file downloads.
- WebView for online payment pages.
- permission_handler for storage and notification permissions.
- cached_network_image, carousel_slider, lottie, photo_view, shimmer, chewie, video_player, and related UI packages.

## Project Structure

```text
lib/
  main.dart                        # App entry point; MultiBlocProvider + MaterialApp.router
  firebase_options.dart
  global_safe_area_wrapper.dart
  injection_container.dart         # get_it dependency registration
  core/
    constants/                     # API URLs, colors, icons, strings, sizes
    init/
      app_start_init.dart          # Startup sequence: Hive, Firebase, DI
    l10n/
      app_translations.dart        # Turkmen (tk) and Russian (ru) translations
    network/
      api_client.dart              # Dio client with Bearer token interceptor
    result/
      result.dart                  # Sealed Result<T> (Success / Failure)
    router/
      app_router.dart              # go_router configuration and route tree
    services/                      # Firebase Messaging, local notifications, deep links
    storage/
      local_storage.dart           # Hive-backed persistence (auth, settings, cart, favorites)
    theme/                         # AppTheme, ColorConstants
    usecase/
      usecase.dart                 # Abstract UseCase<Type, Params> interfaces
    utils/                         # Dialog utils, upgrader localization
    widgets/                       # Shared loading widget
  features/
    ai_chat/                       # AI/socket-based chat
    auth/                          # Phone OTP login, token management
    cart/                          # Local cart (Hive) + order creation
    favorites/                     # Favorite collars and products
    home/                          # Banners, categories, product lists, balance
    product_detail/                # Product/collar detail page
    search/                        # Collar search
    shell/                         # Bottom navigation ShellRoute wrapper
    user_profile/                  # Profile, downloaded files, settings
assets/
  fonts/
  icons/
  image/
  image/instruction/
  lottie/
  videos/
android/
ios/
```

Each feature under `features/` follows Clean Architecture layers:

```text
features/<name>/
  data/
    datasources/    # Remote (Dio/HTTP) and local (Hive) data sources
    models/         # JSON-serializable models
    repositories/   # Concrete repository implementations
  domain/
    entities/       # Pure Dart entities
    repositories/   # Abstract repository interfaces
    usecases/       # Single-responsibility use case classes
  presentation/
    bloc/           # BLoC: *_bloc.dart, *_event.dart, *_state.dart
    pages/          # Screen widgets
    widgets/        # Feature-scoped widgets
```

## App Startup Workflow

1. `main.dart` calls `AppStartInit.init()`.
2. Startup initializes Flutter bindings, Hive (`LocalStorage`), Firebase, local notifications, Firebase Analytics, and portrait orientation. Then runs `initDependencies()` to register all get_it singletons and factories.
3. `MaterialApp.router` mounts the go_router configuration with a global `MultiBlocProvider` providing `AuthBloc`, `HomeBloc`, `BalanceBloc`, `CartBloc`, and `FavoritesBloc`.
4. The initial route is `/splash` → `SplashPage`, which reads the stored token via `AuthBloc` to determine auth state.
5. If authenticated, go_router redirects to `/home` (a `ShellRoute` with bottom navigation tabs: Home, Cart, Favorites, Profile).
6. If not authenticated, go_router redirects to `/login` → `LoginPage` → `OtpPage`.

## User Workflow

### Browse and Search

1. User opens the app and lands on the home tab.
2. Home loads banners, categories, machines, collars, clothes/new products, sewing goods, and current balance.
3. User can browse horizontal product lists, open all-products views, filter/sort by price/date/views, search collars, and open product details.
4. Product detail pages show images, metadata, price, category/tag, views/download count, optional video, and actions.

### Login

1. User enters a phone number in the login screen.
2. `POST /api/v1/login` sends an OTP.
3. User enters the OTP.
4. `POST /api/v1/login/verify` returns `api_token`.
5. The token and phone number are saved through the Hive-backed `LocalStorage` service.
6. Logged-in features such as favorites, wallet, orders, downloads, and purchase actions use `Authorization: Bearer <token>`.

### Favorites

1. User taps the favorite action on a product or collar.
2. The app calls the matching favorite endpoint for regular products or collars.
3. Favorites are refreshed through `FavoritesController`.
4. The favorites tab displays saved collars and saved products.

### Cart and Orders

1. User adds physical products to the cart.
2. Cart data is stored locally through the Hive-backed `LocalStorage` service.
3. User opens the cart and fills order information: name, address, province, phone, and note.
4. `OrderService` posts order data to `POST /api/v1/users/me/orders`.
5. If payment is disabled remotely, order creation is simulated locally for store-compliance mode.

### Wallet and Payment

1. The profile/settings area exposes `Add money`.
2. User can choose phone payment or online card payment.
3. Online card payment starts through `POST /api/v1/online-transactions` and opens the returned URL in a WebView.
4. The app periodically refreshes user balance.
5. `PaymentStatusController` reads `GET /api/v1/payment-status`.
6. When `payment_status` is true, payment-dependent UI and behavior are disabled or restricted.

### Collar Download

1. User opens a downloadable collar.
2. The app loads machine-specific file options from the collar detail endpoint.
3. If the item is not purchased, the app checks the wallet balance unless payment is disabled.
4. On Android, downloaded/copyable files are organized under the fixed `Download/YAKA` source root.
5. Inside `Download/YAKA`, files must be stored with the machine-specific mapped structure from `MachineUsbPathMapper.pathsByMachine`. Do not save new downloads as `<MACHINE>/<PRODUCT_NAME>`.
6. The profile open downloaded collars action opens `Download/YAKA` when available; if it cannot open that folder, it falls back to the default Downloads folder.
7. The copy-to-USB screen lists product folders from the mapped source structure and preserves that same relative path when copying.
8. `DownloadsService.downloadFile()` calls `POST /api/v1/users/me/downloads`.
9. Returned file URLs are saved into:
   - Android source/save folder: machine-specific mapped path, described below
   - USB target folder: the same machine-specific mapped path
   - iOS: app documents directory under `YAKA/<MAPPED_PATH>/`
10. Download progress is shown and the local purchased/downloaded state is refreshed.

Android download and USB path mapping:

| Machine/category name | Required relative folder under `Download/YAKA`, iOS `YAKA`, and USB root |
| --- | --- |
| `DST 20x28 MAŞYNLAR ÜÇIN` | `<PRODUCT_NAME>/` |
| `15 IŇŇE ÜÇIN` | `<PRODUCT_NAME>/` |
| `Janome MB4-MB4S` | `EMB/<PRODUCT_NAME>/` |
| `Janome 450E-500E` | `EMB/<PRODUCT_NAME>/` |
| `Janome 350E-370E` | `EmbF5/<PRODUCT_NAME>/` |
| `Janome 200E-230E` | `EMB/<PRODUCT_NAME>/` |
| `Brother v3` | `<PRODUCT_NAME>/` |
| `Bernetta 340` | `EmbF5/<PRODUCT_NAME>/` |

Example: when downloading product `Y2010` for `Janome MB4-MB4S`, save it as `Download/YAKA/EMB/Y2010/file.dst`, and copying to USB writes `EMB/Y2010/file.dst`. For `Brother v3`, save it as `Download/YAKA/Y2010/file.dst`, and copying to USB writes `Y2010/file.dst`.

The mapping table is the source of truth. New code must check the machine name through `MachineUsbPathMapper.pathsByMachine` and must not introduce the previous `<MACHINE>/<PRODUCT_NAME>` download structure.

### Android USB Save Workflow

Android does not reliably allow apps to write directly to removable USB paths such as `/storage/...` on modern versions. The app therefore uses Android's Storage Access Framework (SAF), which is the legal and Play-policy-friendly approach for writing to user-selected external storage.

Workflow:

1. Android downloads are saved under the fixed `Download/YAKA` source root.
2. The app scans `Download/YAKA` recursively and groups files by the mapped product folders.
3. The copy-to-USB screen shows USB connection status. If no USB stick is mounted, it shows the translated “connect USB stick” status and blocks copy.
4. The user selects one or more product folders. Selection is folder-level, not individual-file level.
5. When copying, every file inside the selected product folder is sent to native Android with the mapped USB `relativePath`.
6. Native Android code creates the mapped target folder path on the selected USB folder with `DocumentsContract`, then writes or replaces each file.

The app intentionally avoids `MANAGE_EXTERNAL_STORAGE` and raw filesystem writes for USB storage. If the user changes USB sticks, revokes storage access, selects the wrong USB folder, or wants a different phone save folder, the stored access can be requested again through the native USB storage channel and copy-to-USB screen.

### Notifications and Deep Links

1. Firebase Messaging requests alert, badge, and sound permissions.
2. Foreground FCM messages are shown through local notifications.
3. Background/terminated messages are handled by a top-level background handler.
4. Notification payloads can include:
   - `android_link`: opens an external Android link.
   - `ios_link`: opens an external iOS link.
   - `product_id`: fetches a product/collar and opens `ProductProfilView`.

## API Surface Used by the App

Base URL: `https://yashelektrik.com`

Authentication:

- `POST /api/v1/login`
- `POST /api/v1/login/verify`

Catalog:

- `GET /api/v1/banners`
- `GET /api/v1/banners/{id}`
- `GET /api/v1/categories`
- `GET /api/v1/categories/{id}`
- `GET /api/v1/collars`
- `GET /api/v1/collars/{id}`
- `GET /api/v1/products`
- `GET /api/v1/products/{id}`
- `GET /api/v1/sewing-products`
- `GET /api/v1/machines`

User:

- `GET /api/v1/users/me`
- `GET /api/v1/users/me/orders`
- `GET /api/v1/users/me/orders/{id}`
- `POST /api/v1/users/me/orders`
- `GET /api/v1/users/me/downloads`
- `POST /api/v1/users/me/downloads`
- `GET /api/v1/users/me/favorites`
- `POST /api/v1/users/me/favorites`
- `DELETE /api/v1/users/me/favorites`
- `GET /api/v1/users/me/favorite-products`
- `POST /api/v1/users/me/favorite-products`
- `DELETE /api/v1/users/me/favorite-products`

Payments and content:

- `GET /api/v1/payment-status`
- `POST /api/v1/online-transactions`
- `GET /api/v1/phone`
- `GET /api/v1/about/`
- `GET /api/v1/faqs`
- `GET /api/v1/tags`

## Local Storage Keys

Stored via `LocalStorage` (Hive). Box → key → purpose:

- `auth` box: `access_token` (bearer token), `customer_id`, `phone`
- `settings` box: `lang_code` (selected locale: `tk` or `ru`), `seen_fab_tutorial`, `notification_permission_requested`, `last_seen_message_id`
- `cart` box: `cart_list` (JSON-encoded local cart products)
- `favorites` box: `fav_product_ids`, `fav_collar_ids` (JSON-encoded ID lists)

## Setup

### Prerequisites

- Flutter SDK compatible with Dart `>=3.13.0 <4.0.0` (CI pins Flutter 3.47.8).
- Android Studio or Xcode for native builds.
- Firebase project configuration files:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `lib/firebase_options.dart`

### Install Dependencies

```bash
flutter pub get
```

### Run

```bash
flutter run
```

Run a specific target:

```bash
flutter run -d android
flutter run -d ios
```

## Build

Android release signing uses either ignored `android/key.properties` or the `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`, and `ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD` environment variables. Keep the signing files and passwords outside Git. A debug APK cannot be published as a release.

Android APK:

```bash
flutter build apk --release
```

Android App Bundle:

```bash
flutter build appbundle --release
```

iOS:

```bash
flutter build ios --release
```

## Quality Checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

CI runs these checks on PRs and `main`, plus an iOS build without signing. The local FlutterFire and video-thumbnail forks under `third_party/` are excluded from app linting but still compiled by platform builds.

## Review and release

Work on a branch with focused Conventional Commits, open a PR with changes and test evidence, resolve review comments, and merge only after green CI and review. Tag the exact validated commit for a GitHub Release. Attach a signed APK only after verifying the certificate against Google Play's **app signing certificate** and testing installation on a real Android device; an upload-key APK may not update a Play-installed app. Link iOS users to the App Store rather than a general-purpose IPA.

See [release readiness](docs/release-readiness.md) for the current backend, privacy, signing, and device checks. A source build is not a store rollout.

## Development Notes

- Keep user-facing strings in `lib/core/l10n/app_translations.dart`. Turkmen key is `'tk'`, Russian is `'ru'`.
- Keep shared colors, icons, and theme constants under `lib/core/theme/` and `lib/core/constants/`.
- New features follow Clean Architecture: add `domain/` → `data/` → `presentation/` layers under `features/<name>/`.
- Register new repositories, data sources, use cases, and BLoCs in `lib/injection_container.dart` (singletons for repos/sources/use cases; factories for BLoCs).
- Use the `Result<T>` sealed class (`core/result/result.dart`) for all repository and use case return types.
- The cart is local-first through Hive (`LocalStorage.cartJson`); orders are sent only from the order screen.
- Payments can be remotely disabled by `/api/v1/payment-status`; test both enabled and disabled modes.
- Download logic is platform-specific. Verify Android USB saving through the system folder picker and iOS document downloads after changes.
- Notification routing depends on payload field names, so coordinate backend payload changes with `NotificationDeepLinkService`.
- Some source files contain mojibake/encoding artifacts in comments and strings. Be careful when editing localized text.
