default:
    @just --list

# Run the desktop app with hot reload
dev:
    flutter run -d linux

# Build the Linux release bundle and (re)install it into ~/.local, overriding any existing install
reinstall:
    #!/usr/bin/env bash
    set -euo pipefail
    flutter build linux --release
    mkdir -p ~/.local/share/the_system
    cp -r build/linux/x64/release/bundle/* ~/.local/share/the_system/
    mkdir -p ~/.local/bin
    ln -sf ~/.local/share/the_system/the_system ~/.local/bin/the_system
    mkdir -p ~/.local/share/applications
    cat <<EOF > ~/.local/share/applications/com.koljasam.the_system.desktop
    [Desktop Entry]
    Type=Application
    Name=the-system
    Exec=$HOME/.local/share/the_system/the_system
    Icon=$HOME/.local/share/the_system/data/flutter_assets/assets/icon.png
    Categories=Utility;
    StartupWMClass=com.koljasam.the_system
    EOF

# Build the debug APK and drop into its output directory (e.g. to run adb install)
apk:
    flutter build apk --debug
    cd build/app/outputs/flutter-apk && exec $SHELL
