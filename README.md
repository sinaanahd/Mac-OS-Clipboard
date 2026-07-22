# Pasteboard

Pasteboard is a native, lightweight, local-only macOS clipboard history and screenshot utility built with SwiftUI and AppKit.

Current version: **1.1.2** (baseline: 1.0.0). Ordinary publishable changes increment the patch component; substantial feature releases increment the minor component and reset patch to zero.

The supplied PasteBoard clipboard-and-history artwork is the approved application icon and is preserved at `Design/Source/PasteBoard-AppIcon.png`. It must not be replaced or reinterpreted without an explicit user request. The menu bar intentionally uses a separate monochrome template asset.

## Requirements

- macOS 14 or later on Apple Silicon
- Xcode 26 or later
- XcodeGen 2.46 or later

## Generate, build, and test

```bash
xcodegen generate
xcodebuild -project Pasteboard.xcodeproj -scheme Pasteboard -configuration Debug -destination "platform=macOS" build
xcodebuild -project Pasteboard.xcodeproj -scheme Pasteboard -destination "platform=macOS" test
```

The app monitors text, image, and Finder file selections locally, keeps bounded persistent history, and presents searchable entries with native previews in a floating panel. It skips pasteboard items marked concealed, transient, or auto-generated. Use ⌥V to show history and ⌥⇧4 to open macOS's built-in interactive region selector. Pasteboard waits for the native capture to finish saving, imports it, and places it on the macOS pasteboard for immediate Command-V. Selecting a history entry restores it to the pasteboard and, with user-granted Accessibility access, pastes it into the previously active app. The menu-bar Clear History action removes local metadata and Pasteboard-owned image copies after confirmation without deleting referenced user files.
