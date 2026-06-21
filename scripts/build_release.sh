#!/usr/bin/env bash
#
# Build, sign (Developer ID), notarize, staple, and package OpenLid for distribution.
# Produces build/dist/OpenLid-<version>.zip and OpenLid-<version>.dmg.
#
# Usage:
#   scripts/build_release.sh
#
# Environment:
#   TEAM_ID        Apple Developer Team ID (default: 6D56G8D849)
#   NOTARY_PROFILE notarytool keychain profile name (default: OpenLid-Notary)
#   SKIP_NOTARIZE  set to 1 to sign only (skip notarization + stapling)
#
set -euo pipefail
cd "$(dirname "$0")/.."

SCHEME="OpenLid"
CONFIG="Release"
TEAM_ID="${TEAM_ID:-6D56G8D849}"
SIGN_ID="${SIGN_ID:-Developer ID Application}"
NOTARY_PROFILE="${NOTARY_PROFILE:-OpenLid-Notary}"
BUILD="build"
DIST="$BUILD/dist"

VERSION="$(xcodebuild -project OpenLid.xcodeproj -showBuildSettings -scheme "$SCHEME" -configuration "$CONFIG" 2>/dev/null \
  | awk -F' = ' '/ MARKETING_VERSION /{print $2; exit}')"
VERSION="${VERSION:-0.0.0}"
APP_NAME="OpenLid"
echo "==> Building $APP_NAME $VERSION"

rm -rf "$BUILD"
mkdir -p "$DIST"

echo "==> Archiving (Developer ID, hardened runtime)"
xcodebuild -project OpenLid.xcodeproj -scheme "$SCHEME" -configuration "$CONFIG" \
  -archivePath "$BUILD/$APP_NAME.xcarchive" \
  -destination 'generic/platform=macOS' \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$SIGN_ID" \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  ENABLE_HARDENED_RUNTIME=YES \
  archive

echo "==> Exporting signed app"
xcodebuild -exportArchive \
  -archivePath "$BUILD/$APP_NAME.xcarchive" \
  -exportOptionsPlist scripts/ExportOptions.plist \
  -exportPath "$BUILD/export"

APP="$BUILD/export/$APP_NAME.app"
[ -d "$APP" ] || { echo "Export failed: $APP not found"; exit 1; }

echo "==> Verifying signature"
codesign --verify --deep --strict --verbose=2 "$APP"

ZIP="$DIST/$APP_NAME-$VERSION.zip"
DMG="$DIST/$APP_NAME-$VERSION.dmg"

notarize() {
  local target="$1"
  echo "==> Submitting $(basename "$target") for notarization"
  # CI provides credentials via env vars; locally we use a stored keychain profile.
  if [ -n "${NOTARY_APPLE_ID:-}" ] && [ -n "${NOTARY_PASSWORD:-}" ]; then
    xcrun notarytool submit "$target" \
      --apple-id "$NOTARY_APPLE_ID" --password "$NOTARY_PASSWORD" \
      --team-id "${NOTARY_TEAM_ID:-$TEAM_ID}" --wait
  else
    xcrun notarytool submit "$target" --keychain-profile "$NOTARY_PROFILE" --wait
  fi
}

if [ "${SKIP_NOTARIZE:-0}" = "1" ]; then
  echo "==> SKIP_NOTARIZE=1: signing only, no notarization"
else
  # Notarize the app (submitted as a zip), then staple the .app itself.
  ditto -c -k --keepParent "$APP" "$BUILD/notarize.zip"
  notarize "$BUILD/notarize.zip"
  echo "==> Stapling app"
  xcrun stapler staple "$APP"
fi

echo "==> Creating zip: $ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Creating dmg: $DMG"
DMG_STAGE="$BUILD/dmg"
rm -rf "$DMG_STAGE"; mkdir -p "$DMG_STAGE"
cp -R "$APP" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGE" -ov -format UDZO "$DMG"
codesign --force --timestamp --sign "$SIGN_ID" "$DMG"

if [ "${SKIP_NOTARIZE:-0}" != "1" ]; then
  notarize "$DMG"
  echo "==> Stapling dmg"
  xcrun stapler staple "$DMG"
fi

echo ""
echo "==> Done. Artifacts:"
ls -lh "$DIST"
echo "$VERSION" > "$BUILD/VERSION"
