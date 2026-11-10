# TakoPlay

TakoPlay is an educational Flutter app for browsing an anime catalog, finding
titles, saving favourites, tracking recently opened episodes, and handing an
episode to an external web player. It does not host or provide video content.

## Download

[![Download Android APK](https://img.shields.io/badge/Android-Download_APK-3DDC84?logo=android&logoColor=white)](https://github.com/kaungsatthe1n/Tako-Play/releases/latest/download/TakoPlay-release.apk)
[![Download iOS IPA](https://img.shields.io/badge/iOS-Download_IPA-555555?logo=apple&logoColor=white)](https://github.com/kaungsatthe1n/Tako-Play/releases/latest/download/TakoPlay-release.ipa)
[![Add to AltStore](https://img.shields.io/badge/AltStore-Add_Source-8E44AD?logo=apple&logoColor=white)](altstore://source?url=https://github.com/kaungsatthe1n/Tako-Play/releases/latest/download/apps.json)

| Platform | File | Requirement |
| :--- | :--- | :--- |
| Android | `TakoPlay-release.apk` | Android phone or tablet |
| iOS (AltStore) | AltStore source | iPhone/iPad, iOS 15+ |
| iOS (Sideloadly) | `TakoPlay-release.ipa` | iPhone/iPad, iOS 15+, PC/Mac |

> [!WARNING]
> **Only download TakoPlay from this GitHub repository.**
> TakoPlay is not published on the Google Play Store, the Apple App Store,
> or any other app store or download site. If you find TakoPlay there, it
> is not from me — it may be outdated, modified, or contain malware. Do
> not install it.

New to iOS sideloading? Follow the [installation manual](#install-on-ios-sideload)
below.

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
- Native HLS playback in BetterPlayer, with source-provided player fallbacks
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

## Install on Android

1. Download `TakoPlay-release.apk` from the button above.
2. Open the file on your device and allow **Install unknown apps** for your
   browser or file manager if Android asks.
3. Tap **Install**, then open TakoPlay.

## Install on iOS (sideload)

TakoPlay is not on the App Store, so iOS users install the IPA with a
sideloading tool. The IPA is unsigned on purpose: the tool signs it with
**your own Apple ID** on your device. No developer account is needed.

Before you start:

- iPhone or iPad with iOS 15.0 or later
- A free Apple ID
- AltStore **or** Sideloadly (choose one)

### Option A: AltStore (recommended)

AltStore refreshes the app automatically in the background, so it does not
expire after 7 days.

1. Install AltStore on your iPhone from
   [altstore.io](https://altstore.io) (follow its guide; it needs a PC/Mac
   on the same Wi-Fi for the first setup).
2. On your iPhone, tap the **AltStore - Add Source** button above, or open
   AltStore, go to **Sources**, tap **+**, and paste this URL:

   ```text
   https://github.com/kaungsatthe1n/Tako-Play/releases/latest/download/apps.json
   ```

3. Go to **Browse**, find **TakoPlay**, and tap **Install**.
4. To update later, open AltStore and tap **Update** when a new version
   appears.

### Option B: Sideloadly

1. Download and install Sideloadly from
   [sideloadly.io](https://sideloadly.io) on your PC/Mac.
2. Download `TakoPlay-release.ipa` from the button above.
3. Connect your iPhone with a cable (or same Wi-Fi) and open Sideloadly.
4. Drag the IPA into Sideloadly, enter your Apple ID, and click **Start**.
5. On the iPhone, go to **Settings > General > VPN & Device Management**,
   tap your Apple ID, and choose **Trust**.
6. Open TakoPlay.

### Good to know

| Topic | What to expect |
| :--- | :--- |
| 7-day expiry | Lasts 7 days. AltStore auto-refreshes; Sideloadly: reinstall. |
| App limit | A free Apple ID allows at most 3 sideloaded apps. |
| Untrusted Developer | Trust: **Settings > General > VPN & Device Mgmt.** |
| Won't open after a week | Signature expired: refresh or reinstall to fix it. |
| Updates | AltStore: in-app. Sideloadly: download and reinstall. |

## License

Released under the [MIT License](LICENSE).
