#!/usr/bin/env bash
# Build ogpreview.app — a real, double-clickable macOS app bundle.
set -euo pipefail
cd "$(dirname "$0")/.."

# Universal by default so the DMG runs on Intel Macs too. SwiftPM's --arch needs
# full Xcode's xcbuild, which the Command Line Tools alone do not ship, so a
# machine without it falls back to its own architecture. CI has Xcode, so the
# released DMG is always universal.
# UNIVERSAL=0 forces the fast single-architecture build.
ARCH_FLAGS=()
if [ "${UNIVERSAL:-1}" = "1" ]; then
  if [ -d "$(xcode-select -p)/../SharedFrameworks/XCBuild.framework" ]; then
    ARCH_FLAGS=(--arch arm64 --arch x86_64)
  else
    echo "note: full Xcode not selected, building $(uname -m) only (CI builds are universal)"
  fi
fi

swift build -c release "${ARCH_FLAGS[@]}"
BIN="$(swift build -c release "${ARCH_FLAGS[@]}" --show-bin-path)"
APP_VERSION="${APP_VERSION:-0.1}"
APP_BUILD="${APP_BUILD:-$APP_VERSION}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
SPARKLE_FRAMEWORK="$BIN/Sparkle.framework"

APP="ogpreview.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"

cp "$BIN/ogpreview" "$APP/Contents/MacOS/ogpreview"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/ogpreview" 2>/dev/null || true

[ -f "Resources/AppIcon.icns" ] || scripts/make-icon.sh
cp "Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

if [ -d "$SPARKLE_FRAMEWORK" ]; then
  cp -R "$SPARKLE_FRAMEWORK" "$APP/Contents/Frameworks/"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>ogpreview</string>
  <key>CFBundleDisplayName</key><string>ogpreview</string>
  <key>CFBundleIdentifier</key><string>com.neetozone.ogpreview</string>
  <key>CFBundleExecutable</key><string>ogpreview</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>${APP_BUILD}</string>
  <key>CFBundleShortVersionString</key><string>${APP_VERSION}</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>SUEnableInstallerLauncherService</key><true/>
  <key>SUEnableAutomaticChecks</key><true/>
  <key>SUAutomaticallyUpdate</key><true/>
  <key>SUScheduledCheckInterval</key><integer>86400</integer>
  <key>SUFeedURL</key><string>https://github.com/neetozone/ogpreview/releases/latest/download/appcast.xml</string>
  <key>SUPublicEDKey</key><string>aPtkST8xh4P6/JRXHkMLjr2XNOtM/+jd3g2pTqraiEo=</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign "$CODE_SIGN_IDENTITY" "$APP"

echo "Built $APP"
echo "Launch it:   open $APP"
echo "Install it:  cp -R $APP /Applications/"
