#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
BUILD_DIR="$ROOT_DIR/build/local-dmg"
DIST_DIR="$ROOT_DIR/dist"

for tool in xcodegen xcodebuild hdiutil ditto shasum; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "Required tool not found: $tool" >&2
        exit 1
    }
done

if [[ -d "$BUILD_DIR" ]]; then
    /bin/rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR" "$DIST_DIR"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/PasteboardDMG.XXXXXX")"
trap '/bin/rm -rf "$STAGING_DIR"' EXIT

cd "$ROOT_DIR"
xcodegen generate
xcodebuild \
    -project Pasteboard.xcodeproj \
    -scheme Pasteboard \
    -configuration Release \
    -destination "platform=macOS" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    clean build

APP_PATH="$BUILD_DIR/DerivedData/Build/Products/Release/Pasteboard.app"
[[ -d "$APP_PATH" ]] || {
    echo "Release application was not produced at: $APP_PATH" >&2
    exit 1
}

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
[[ -n "$VERSION" ]] || { echo "Could not read the marketing version." >&2; exit 1; }
DMG_PATH="$DIST_DIR/Pasteboard-$VERSION-macOS.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"

ditto "$APP_PATH" "$STAGING_DIR/Pasteboard.app"
ln -s /Applications "$STAGING_DIR/Applications"
hdiutil create -volname "Pasteboard $VERSION" -srcfolder "$STAGING_DIR" \
    -format UDZO -ov "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$CHECKSUM_PATH"

echo "Local unsigned DMG: $DMG_PATH"
echo "SHA-256 checksum: $CHECKSUM_PATH"
echo "This build is not Developer ID signed or notarized. See DISTRIBUTION.md."
