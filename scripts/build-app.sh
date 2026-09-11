#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --product Awake
BIN_DIR="$(swift build -c release --show-bin-path)"
APP_DIR="$PWD/dist/Awake.app"
RES_DIR="$APP_DIR/Contents/Resources"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$RES_DIR"
cp "$BIN_DIR/Awake" "$APP_DIR/Contents/MacOS/Awake"
cp "$PWD/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PWD/Resources/AppIcon.icns" "$RES_DIR/AppIcon.icns"
cp "$PWD/Resources/install-awake-helper.sh" "$RES_DIR/install-awake-helper.sh"
chmod 755 "$RES_DIR/install-awake-helper.sh"
echo -n 'APPL????' > "$APP_DIR/Contents/PkgInfo"

codesign --force --sign - "$APP_DIR"
printf 'Built %s\n' "$APP_DIR"
