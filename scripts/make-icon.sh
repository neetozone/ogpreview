#!/usr/bin/env bash
# Regenerate Resources/AppIcon.icns from Resources/icon.png.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="Resources/icon.png"
SET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$SET"

for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$SRC" --out "$SET/icon_${size}x${size}.png" >/dev/null
  sips -z $((size * 2)) $((size * 2)) "$SRC" --out "$SET/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$SET" -o Resources/AppIcon.icns
echo "Built Resources/AppIcon.icns"
