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

## License

Released under the [MIT License](LICENSE).
