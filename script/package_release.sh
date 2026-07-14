#!/usr/bin/env bash
set -euo pipefail

APP_NAME="DockShelf"
BUNDLE_ID="${BUNDLE_ID:-com.dmitriy.DockShelf}"
APP_VERSION="${APP_VERSION:-1.0}"
BUNDLE_VERSION="${BUNDLE_VERSION:-1}"
MIN_SYSTEM_VERSION="13.0"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
ARCHITECTURE="$(/usr/bin/uname -m)"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_ROOT="$ROOT_DIR/release"
RELEASE_DIR="$RELEASE_ROOT/$APP_NAME-$APP_VERSION"
WORK_ROOT="$(/usr/bin/mktemp -d "/tmp/${APP_NAME}Release.XXXXXX")"
WORK_RELEASE_DIR="$WORK_ROOT/$APP_NAME-$APP_VERSION"
PACKAGE_STAGING_DIR="$WORK_ROOT/package"
ZIP_PATH="$RELEASE_ROOT/$APP_NAME-$APP_VERSION-macOS-$ARCHITECTURE.zip"
DMG_PATH="$RELEASE_ROOT/$APP_NAME-$APP_VERSION-macOS-$ARCHITECTURE.dmg"
RW_DMG_PATH="$WORK_ROOT/$APP_NAME-$APP_VERSION-macOS-$ARCHITECTURE-rw.dmg"
APP_BUNDLE="$WORK_RELEASE_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_FRAMEWORKS="$APP_CONTENTS/Frameworks"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON_GENERATOR="$ROOT_DIR/script/generate_app_icon.swift"
APP_SOURCE_RESOURCES="$ROOT_DIR/Sources/DockShelf/Resources"

cleanup() {
  rm -rf "$WORK_ROOT"
}

trap cleanup EXIT

strip_problem_xattrs() {
  local target="$1"
  local attrs=(
    "com.apple.FinderInfo"
    "com.apple.ResourceFork"
    "com.apple.macl"
    "com.apple.fileprovider.fpfs#P"
  )

  /usr/bin/xattr -cr "$target" 2>/dev/null || true

  while IFS= read -r -d '' path; do
    for attr in "${attrs[@]}"; do
      /usr/bin/xattr -d "$attr" "$path" 2>/dev/null || true
    done
  done < <(/usr/bin/find "$target" -print0)
}

sign_app() {
  local bundle="$1"

  if [[ "$SIGN_IDENTITY" == "-" ]]; then
    /usr/bin/codesign --force --deep --sign - --timestamp=none "$bundle"
  else
    /usr/bin/codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$bundle"
  fi
}

cd "$ROOT_DIR"

swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"

rm -rf "$RELEASE_DIR" "$ZIP_PATH" "$DMG_PATH"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$APP_FRAMEWORKS"

cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
if [[ -d "$(dirname "$BUILD_BINARY")/Sparkle.framework" ]]; then
  ditto "$(dirname "$BUILD_BINARY")/Sparkle.framework" "$APP_FRAMEWORKS/Sparkle.framework"
  /usr/bin/install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BINARY"
fi

if [[ -x "$APP_ICON_GENERATOR" ]]; then
  "$APP_ICON_GENERATOR" "$APP_RESOURCES/AppIcon.icns"
else
  swift "$APP_ICON_GENERATOR" "$APP_RESOURCES/AppIcon.icns"
fi

if [[ -d "$APP_SOURCE_RESOURCES" ]]; then
  ditto "$APP_SOURCE_RESOURCES" "$APP_RESOURCES"
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUNDLE_VERSION</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>SUFeedURL</key>
  <string>https://raw.githubusercontent.com/Jas952/DockShelf/main/.github/appcast.xml</string>
  <key>SUPublicEDKey</key>
  <string>CTjEC8T+/KbYNAF9Tm+GSM9KCQu2+AIuHQSNJJGjV+o=</string>
  <key>SUEnableAutomaticChecks</key>
  <true/>
  <key>SUScheduledCheckInterval</key>
  <integer>86400</integer>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/plutil -lint "$INFO_PLIST" >/dev/null
strip_problem_xattrs "$APP_BUNDLE"

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  SIGNING_DESCRIPTION="ad hoc local signature, no Developer ID"
else
  SIGNING_DESCRIPTION="signed with $SIGN_IDENTITY"
fi

sign_app "$APP_BUNDLE"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE" >/dev/null

cat >"$WORK_RELEASE_DIR/README_RELEASE.md" <<EOF
# DockShelf $APP_VERSION

This folder contains the local macOS application build.

- App bundle: DockShelf.app
- Bundle identifier: $BUNDLE_ID
- Version: $APP_VERSION ($BUNDLE_VERSION)
- Minimum macOS: $MIN_SYSTEM_VERSION
- Architecture: $ARCHITECTURE
- Signing: $SIGNING_DESCRIPTION
- Notarization: not notarized

For private local use, drag DockShelf.app to Applications or launch it directly.
For public distribution, rebuild with a Developer ID certificate and notarize the app.
EOF

ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

mkdir -p "$PACKAGE_STAGING_DIR"
ditto "$APP_BUNDLE" "$PACKAGE_STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$PACKAGE_STAGING_DIR/Applications"
strip_problem_xattrs "$PACKAGE_STAGING_DIR/$APP_NAME.app"
/usr/bin/hdiutil create \
  -volname "$APP_NAME $APP_VERSION" \
  -srcfolder "$PACKAGE_STAGING_DIR" \
  -ov \
  -format UDRW \
  "$RW_DMG_PATH" >/dev/null

DMG_MOUNT_DIR="$(/usr/bin/mktemp -d "/tmp/${APP_NAME}DMG.XXXXXX")"
/usr/bin/hdiutil attach "$RW_DMG_PATH" -readwrite -nobrowse -mountpoint "$DMG_MOUNT_DIR" >/dev/null
strip_problem_xattrs "$DMG_MOUNT_DIR/$APP_NAME.app"
sign_app "$DMG_MOUNT_DIR/$APP_NAME.app" >/dev/null
/usr/bin/codesign --verify --deep --strict --verbose=2 "$DMG_MOUNT_DIR/$APP_NAME.app" >/dev/null
/usr/bin/hdiutil detach "$DMG_MOUNT_DIR" >/dev/null
/bin/rmdir "$DMG_MOUNT_DIR" 2>/dev/null || true
/usr/bin/hdiutil convert "$RW_DMG_PATH" -format UDZO -o "$DMG_PATH" -ov >/dev/null
/bin/rm -f "$RW_DMG_PATH"
rm -rf "$PACKAGE_STAGING_DIR"
strip_problem_xattrs "$APP_BUNDLE"
sign_app "$APP_BUNDLE" >/dev/null
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE" >/dev/null

mkdir -p "$RELEASE_ROOT"
ditto "$WORK_RELEASE_DIR" "$RELEASE_DIR"
strip_problem_xattrs "$RELEASE_DIR/$APP_NAME.app"

echo "Release staged at:"
echo "$RELEASE_DIR"
echo
echo "Installable artifacts:"
echo "$ZIP_PATH"
echo "$DMG_PATH"
