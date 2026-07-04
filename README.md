# the-system

A Flutter app for a growing suite of personal-notes flows, backed by a plain folder of JSON files on disk. Targets Linux desktop and Android (sideload) only.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/install) (stable channel)
- Android SDK + NDK (via `flutter doctor` / Android Studio, or a standalone `cmdline-tools` setup) for the Android target
- Linux desktop build tools: `sudo apt install cmake ninja-build clang libgtk-3-dev`

## Setup

```bash
flutter pub get
```

## Development

```bash
flutter run -d linux    # desktop app, with hot reload
flutter run -d <device> # Android device/emulator
```

On first launch, the app asks for a data folder:
- **Linux**: a native folder picker, backed by a real filesystem path.
- **Android**: requests "All files access" (`MANAGE_EXTERNAL_STORAGE`) — a manual one-time toggle — then asks for a plain path (e.g. `/storage/emulated/0/Documents/the-system`). No Storage Access Framework/`content://` URIs are used, so a sync tool like Syncthing can point at the exact same folder on both platforms.

## Build

```bash
flutter build linux         # Linux desktop bundle
flutter build apk --debug   # debug APK, auto-signed, ready to sideload
```

Install a built APK: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`

## Analysis & tests

```bash
flutter analyze
flutter test
```

## Data format

Notes are flat `*.json` files directly inside the data folder. Each file has at least a `primaryType` field; flow-specific fields (e.g. `title`, `body`, `triaged`) vary by note type. See `example_file_1.json` / `example_file_2.json` for samples.

## Flows

- **Scratchpad Triage** — surfaces notes with `primaryType: "scratchpad"` and no `triaged: "true"` one at a time, in random order, with Keep / Delete / Defer actions. Delete offers an Undo snackbar.
