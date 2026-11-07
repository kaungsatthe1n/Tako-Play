# TakoPlay

TakoPlay is an educational Flutter app for browsing an anime catalog, finding
titles, saving favourites, tracking recently opened episodes, and handing an
episode to an external web player. It does not host or provide video content.

## Screenshots

Current iPhone simulator captures of the redesigned interface.

| Discover | Update prompt |
| :---: | :---: |
| ![TakoPlay Discover screen](assets/screenshots/discover-current.jpg) | ![TakoPlay update available prompt](assets/screenshots/update-current.jpg) |

## Features

- Popular, recently added, and movie catalog sections
- Search with recent-query history
- Episode lists, saved titles, and watchlist progress
- Genre browsing and pagination
- External WebView player handoff with source-provided fallback URLs
- Player-type and preferred-quality settings
- Release update checks

## Requirements

- Flutter SDK 3.32 or later
- Xcode for iOS simulator builds
- Android Studio and an Android SDK for Android builds

## Get started

```bash
git clone https://github.com/kaungsatthe1n/Tako-Play.git
cd Tako-Play
flutter pub get
flutter run
```

The default catalog source can be changed for an owned deployment:

```bash
flutter run --dart-define=SOURCE_BASE_URL=https://catalog.example.com
```

## Testing

Run the unit and widget suite:

```bash
flutter analyze
flutter test
```

Run named end-to-end flows on a connected simulator or device:

```bash
flutter test integration_test/home_catalog_detail_flow_test.dart -d <device-id>
flutter test integration_test/search_flow_test.dart -d <device-id>
flutter test integration_test/library_flow_test.dart -d <device-id>
flutter test integration_test/watchlist_flow_test.dart -d <device-id>
flutter test integration_test/episode_error_and_recent_flow_test.dart -d <device-id>
flutter test integration_test/detail_error_recovery_flow_test.dart -d <device-id>
flutter test integration_test/drawer_preferences_and_about_flow_test.dart -d <device-id>
```

The end-to-end flows use local catalog fixtures, so they do not depend on a
live catalog or player page.

## License

Released under the [MIT License](LICENSE).
