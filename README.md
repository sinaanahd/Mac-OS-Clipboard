# Pasteboard

Pasteboard is a native, lightweight, local-only macOS clipboard history and screenshot utility built with SwiftUI and AppKit.

Current version: **1.2.3** (build 8; baseline: 1.0.0). Ordinary publishable changes increment the patch component; substantial feature releases increment the minor component and reset patch to zero.

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

GitHub Actions regenerates, builds, and tests the project on macOS 14 with Xcode 16.2, macOS 15 with Xcode 26.3, and macOS 26 with Xcode 26.5. CI validates compilation and automated behavior; permission prompts, Gatekeeper, appearance, and interaction quality still require the manual checklist.

The current release-candidate evidence and remaining OS-specific checks are tracked in [RELEASE_VALIDATION.md](RELEASE_VALIDATION.md).

Pasteboard 1.2 adds native settings for both global shortcuts, unpinned history and image limits, expiration, automatic paste, monitoring, launch at login, panel placement, screenshot completion, exclusions, storage inspection, and cleanup. Defaults remain 200 unpinned entries and 50 unpinned images; pins do not count toward either limit. Clipboard metadata is written as coalesced atomic JSON and image payloads remain separate local files.

On macOS 26, functional header/search surfaces adopt restrained system Liquid Glass. macOS 14 and 15 use native material fallbacks. Short animations respect Reduce Motion, while system materials adapt to Reduced Transparency and Increased Contrast.

## Local distribution

Build the credential-free local DMG with:

```bash
./scripts/build-local-dmg.sh
```

Versioned DMGs and their matching checksums are retained in the tracked [release archive](dist/README.md), allowing users to download an earlier build if a newer release regresses. Verify the checksum before installation. These local builds are not Developer ID signed or notarized; see [DISTRIBUTION.md](DISTRIBUTION.md) for the legitimate Gatekeeper flow, permissions, removal, archive policy, and the separate optional notarization workflow.
