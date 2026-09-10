#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" ]]; then
  printf 'This package is for macOS arm64. This Mac is %s.\n' "$ARCH" >&2
  exit 1
fi

./scripts/build-app.sh
BIN="$PWD/dist/Awake.app/Contents/MacOS/Awake"
BIN_ARCH="$(lipo -archs "$BIN")"
if [[ "$BIN_ARCH" != "arm64" ]]; then
  printf 'Expected arm64 binary, got: %s\n' "$BIN_ARCH" >&2
  exit 1
fi

ZIP="$PWD/dist/Awake-${VERSION}-macos-arm64.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$PWD/dist/Awake.app" "$ZIP"
printf 'Packed %s (%s)\n' "$ZIP" "$(lipo -archs "$BIN")"
shasum -a 256 "$ZIP"
