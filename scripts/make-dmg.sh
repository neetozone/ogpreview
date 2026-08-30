#!/usr/bin/env bash
# Build ogpreview-macos.dmg — the drag-to-Applications disk image.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_VERSION="${APP_VERSION:-0.1}"
APP_BUILD="${APP_BUILD:-$APP_VERSION}"
DMG_NAME="${DMG_NAME:-ogpreview-macos.dmg}"
STAGING_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

APP_VERSION="$APP_VERSION" APP_BUILD="$APP_BUILD" scripts/make-app.sh

cp -R ogpreview.app "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"
rm -f "$DMG_NAME"

hdiutil create \
  -volname "ogpreview" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_NAME"
