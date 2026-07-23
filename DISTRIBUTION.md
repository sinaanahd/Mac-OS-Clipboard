# Distribution

Pasteboard has a required local DMG workflow and a separate optional Developer ID workflow. The local workflow needs no Apple Developer Program membership or Apple credentials.

## Local DMG

Run:

```bash
./scripts/build-local-dmg.sh
```

The script regenerates the Xcode project, performs a clean unsigned Release build, and creates:

```text
dist/Pasteboard-1.2.3-macOS.dmg
dist/Pasteboard-1.2.3-macOS.dmg.sha256
```

The version in the filename is read from the built application. The image contains `Pasteboard.app` and an `Applications` symlink. Verify it with:

```bash
hdiutil verify "dist/Pasteboard-1.2.3-macOS.dmg"
shasum -a 256 "dist/Pasteboard-1.2.3-macOS.dmg"
shasum -a 256 -c "dist/Pasteboard-1.2.3-macOS.dmg.sha256"
```

## Version archive

Checksum-verified, versioned DMGs and their matching `.sha256` files are committed under `dist/`. Keep older releases available so users can roll back if a newer version regresses. The archive index is [dist/README.md](dist/README.md).

Before committing an artifact:

1. Build it with the documented packaging script.
2. Confirm the filename version matches the bundle metadata.
3. Run `hdiutil verify` and `shasum -a 256 -c`.
4. Add the DMG, checksum, and archive-index entry together.

Do not place unpackaged `.app` bundles, temporary build output, credentials, certificates, provisioning profiles, or unversioned artifacts in `dist/`. GitHub is a convenience archive, not a substitute for Developer ID signing or notarization. Older versions may contain bugs fixed by later releases.

This local build is not Developer ID signed or notarized. Gatekeeper may therefore warn or block it even when it came from a trusted sender. Do not disable Gatekeeper or remove quarantine automatically. For a trusted private build:

1. Mount the DMG and drag Pasteboard to Applications.
2. Attempt to open Pasteboard.
3. If macOS blocks it, open System Settings › Privacy & Security.
4. Use the available Open Anyway action and confirm only after verifying the sender and checksum.

## Permissions

Pasteboard can request Accessibility only to send one Command-V when automatic paste is enabled. It requests Screen Recording only for interactive region capture. Clipboard history and screenshots stay in local Application Support; no content is uploaded and the app has no analytics.

Automatic paste can be disabled, in which case no Accessibility permission is needed. Screen capture can be avoided without affecting ordinary clipboard history.

## Removal

Quit Pasteboard, remove `/Applications/Pasteboard.app`, and disable its login item in System Settings if enabled. History is not deleted automatically. To remove it explicitly, delete:

```text
~/Library/Application Support/Pasteboard/
```

Preferences may be removed separately with `defaults delete com.sinaanahd.Pasteboard`. These actions are intentionally manual and destructive.

## Optional signed and notarized DMG

Developer ID distribution requires paid Apple Developer Program access, a locally installed `Developer ID Application` certificate/private key, a Team ID, and a `notarytool` keychain profile. Store credentials securely:

```bash
xcrun notarytool store-credentials "pasteboard-notary"
```

Then provide configuration to the process without committing it:

```bash
export DEVELOPER_ID_APPLICATION="Developer ID Application: Name (TEAMID)"
export APPLE_TEAM_ID="TEAMID"
export NOTARY_KEYCHAIN_PROFILE="pasteboard-notary"
./scripts/build-notarized-dmg.sh
```

The optional script enables hardened runtime, archives and signs the app, verifies its signature, builds and signs the DMG, submits it with current `notarytool`, staples and validates the ticket, runs Gatekeeper assessment, and generates a checksum. If credentials are absent, it exits with an explanation and leaves any successful local DMG untouched. Debug builds, tests, and the local DMG never depend on these credentials.
