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

### Installing the Linux build on Ubuntu

`flutter build linux` produces a self-contained bundle at `build/linux/x64/release/bundle/` (or `arm64` on ARM). For personal use on a single machine, a `.deb`/AppImage/Snap build is unnecessary ceremony — just install the bundle into your user directory (no `sudo` needed):

```bash
flutter build linux --release

mkdir -p ~/.local/share/the_system
cp -r build/linux/x64/release/bundle/* ~/.local/share/the_system/
mkdir -p ~/.local/bin
ln -sf ~/.local/share/the_system/the_system ~/.local/bin/the_system
```

Then add a desktop entry so it shows up in the app launcher:

```bash
mkdir -p ~/.local/share/applications
cat <<EOF > ~/.local/share/applications/the_system.desktop
[Desktop Entry]
Type=Application
Name=the-system
Exec=$HOME/.local/share/the_system/the_system
Icon=$HOME/.local/share/the_system/data/flutter_assets/assets/icon.png
Categories=Utility;
EOF
```

(Skip the `Icon=` line, or point it at your own icon, if `assets/icon.png` doesn't exist.)

To update after pulling new changes, just rebuild and re-copy over the installed bundle — no reinstall needed:

```bash
flutter build linux --release
cp -r build/linux/x64/release/bundle/* ~/.local/share/the_system/
```

## Analysis & tests

```bash
flutter analyze
flutter test
```

## Data format

Notes are flat `*.json` files directly inside the data folder. Each file has at least a `primaryType` field; flow-specific fields (e.g. `title`, `body`, `triaged`) vary by note type. See `example_file_1.json` / `example_file_2.json` for samples.

## Flows

- **Scratchpad Triage** — surfaces notes with `primaryType: "scratchpad"` and no `triaged: "true"` one at a time, in random order, with Keep / Delete / Defer actions. Delete offers an Undo snackbar.
