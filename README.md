# Pasteboard

Pasteboard is a native, lightweight, local-only macOS clipboard history and screenshot utility built with SwiftUI and AppKit.

Current version: **1.2.0** (build 5; baseline: 1.0.0). Ordinary publishable changes increment the patch component; substantial feature releases increment the minor component and reset patch to zero.

The supplied PasteBoard clipboard-and-history artwork is the approved application icon and is preserved at `Design/Source/PasteBoard-AppIcon.png`. It must not be replaced or reinterpreted without an explicit user request. The menu bar intentionally uses a separate monochrome template asset.

## Requirements

- macOS 14 or later; Apple Silicon is supported and local Release packages are universal (`arm64` and `x86_64`)
- Xcode 26 or later
- XcodeGen 2.46 or later

## Generate, build, and test

```bash
xcodegen generate
xcodebuild -project Pasteboard.xcodeproj -scheme Pasteboard -configuration Debug -destination "platform=macOS" build
xcodebuild -project Pasteboard.xcodeproj -scheme Pasteboard -destination "platform=macOS" test
```

The app monitors text, image, and Finder file selections locally, keeps bounded persistent history, and presents searchable entries with native previews in a floating panel. It skips concealed, transient, auto-generated, and user-excluded application content. Use ⌥V to show history and ⌥⇧4 to open macOS's built-in interactive region selector.

Pasteboard 1.2 adds native settings for both global shortcuts, unpinned history and image limits, expiration, automatic paste, monitoring, launch at login, panel placement, screenshot completion, exclusions, storage inspection, and cleanup. Defaults remain 200 unpinned entries and 50 unpinned images; pins do not count toward either limit. Clipboard metadata is written as coalesced atomic JSON and image payloads remain separate local files.

On macOS 26, functional header/search surfaces adopt restrained system Liquid Glass. macOS 14 and 15 use native material fallbacks. Short animations respect Reduce Motion, while system materials adapt to Reduced Transparency and Increased Contrast.

## Local distribution

Build the credential-free local DMG with:

```bash
./scripts/build-local-dmg.sh
```

Output is written to ignored `dist/`. This build is not Developer ID signed or notarized; see [DISTRIBUTION.md](DISTRIBUTION.md) for checksum verification, the legitimate Gatekeeper flow, permissions, removal, and the separate optional notarization workflow.
