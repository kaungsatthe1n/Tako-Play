# TakoPlay

TakoPlay is an educational Flutter app for browsing an anime catalog, finding
titles, saving favourites, tracking recently opened episodes, and handing an
episode to an external web player. It does not host or provide video content.

## Screenshots

Current iPhone simulator captures of the redesigned interface.

| Discover | Watchlist |
| :---: | :---: |
| ![TakoPlay Discover screen](assets/screenshots/discover-current.jpg) | ![TakoPlay Watchlist screen](assets/screenshots/watchlist-current.jpg) |

| Search | Title detail |
| :---: | :---: |
| ![TakoPlay search screen](assets/screenshots/search-bleach-current.jpg) | ![TakoPlay title detail screen](assets/screenshots/anime-detail-current.jpg) |

| Movie detail |
| :---: |
| ![TakoPlay movie detail screen](assets/screenshots/movie-detail-current.jpg) |

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

## License

Released under the [MIT License](LICENSE).
