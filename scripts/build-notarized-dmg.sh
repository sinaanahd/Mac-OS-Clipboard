#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
BUILD_DIR="$ROOT_DIR/build/notarized-dmg"
DIST_DIR="$ROOT_DIR/dist"

if [[ -z "${DEVELOPER_ID_APPLICATION:-}" || -z "${APPLE_TEAM_ID:-}" || -z "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
    echo "Notarized distribution requires DEVELOPER_ID_APPLICATION, APPLE_TEAM_ID, and NOTARY_KEYCHAIN_PROFILE." >&2
    echo "Create the keychain profile with xcrun notarytool store-credentials; never place credentials in this repository." >&2
    echo "Any existing unsigned DMG under $DIST_DIR remains unchanged." >&2
    exit 2
fi

for tool in xcodegen xcodebuild codesign hdiutil xcrun spctl shasum ditto; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "Required tool not found: $tool" >&2
        exit 1
    }
done

if [[ -d "$BUILD_DIR" ]]; then
    /bin/rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR" "$DIST_DIR"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/PasteboardNotary.XXXXXX")"
trap '/bin/rm -rf "$STAGING_DIR"' EXIT

cd "$ROOT_DIR"
xcodegen generate
xcodebuild archive \
    -project Pasteboard.xcodeproj \
    -scheme Pasteboard \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$BUILD_DIR/Pasteboard.xcarchive" \
    CODE_SIGNING_ALLOWED=YES \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$DEVELOPER_ID_APPLICATION" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    ENABLE_HARDENED_RUNTIME=YES

APP_PATH="$BUILD_DIR/Pasteboard.xcarchive/Products/Applications/Pasteboard.app"
[[ -d "$APP_PATH" ]] || { echo "Signed archive did not contain Pasteboard.app." >&2; exit 1; }
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
DMG_PATH="$DIST_DIR/Pasteboard-$VERSION-macOS-notarized.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"

ditto "$APP_PATH" "$STAGING_DIR/Pasteboard.app"
ln -s /Applications "$STAGING_DIR/Applications"
hdiutil create -volname "Pasteboard $VERSION" -srcfolder "$STAGING_DIR" \
    -format UDZO -ov "$DMG_PATH"
codesign --force --sign "$DEVELOPER_ID_APPLICATION" "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$CHECKSUM_PATH"

echo "Notarized DMG: $DMG_PATH"
echo "SHA-256 checksum: $CHECKSUM_PATH"
