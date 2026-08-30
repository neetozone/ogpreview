#!/usr/bin/env bash
# Build the app bundle, check it is put together correctly, and prove it opens a
# window. UNIVERSAL=0 keeps CI fast; releases build universal.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/make-app.sh

APP="ogpreview.app"
PLIST="$APP/Contents/Info.plist"

for key in CFBundleIdentifier CFBundleIconFile SUFeedURL SUPublicEDKey; do
  /usr/libexec/PlistBuddy -c "Print :$key" "$PLIST" >/dev/null \
    || { echo "FAIL: $key missing from Info.plist"; exit 1; }
done

[ -d "$APP/Contents/Frameworks/Sparkle.framework" ] \
  || { echo "FAIL: Sparkle.framework not bundled"; exit 1; }
[ -f "$APP/Contents/Resources/AppIcon.icns" ] \
  || { echo "FAIL: AppIcon.icns not bundled"; exit 1; }

codesign --verify --deep "$APP" || { echo "FAIL: code signature invalid"; exit 1; }
echo "PASS: bundle checks ($(lipo -archs "$APP/Contents/MacOS/ogpreview"))"

"$APP/Contents/MacOS/ogpreview" &
APP_PID=$!
trap 'kill "$APP_PID" 2>/dev/null || true' EXIT

if swift scripts/window-check.swift 45; then
  echo "PASS: app opened a window"
else
  echo "FAIL: app started but never opened a window"
  exit 1
fi
