#!/bin/bash
# Renders icon/AppIcon.svg into Resources/AppIcon.png and Resources/AppIcon.icns.
# Needs rsvg-convert (brew install librsvg) and iconutil (ships with macOS).
set -euo pipefail
cd "$(dirname "$0")/.."

SVG=icon/AppIcon.svg
SET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$SET"

render() { rsvg-convert -w "$1" -h "$1" "$SVG" -o "$2"; }

for size in 16 32 128 256 512; do
  render "$size" "$SET/icon_${size}x${size}.png"
  render "$((size * 2))" "$SET/icon_${size}x${size}@2x.png"
done

iconutil -c icns "$SET" -o Resources/AppIcon.icns
render 1024 Resources/AppIcon.png
cp Resources/AppIcon.png docs/icon.png
printf 'Wrote Resources/AppIcon.icns and Resources/AppIcon.png\n'
