# Pasteboard

Pasteboard is a native, lightweight, local-only macOS clipboard history and screenshot utility built with SwiftUI and AppKit.

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

The app monitors text, image, and Finder file selections locally, keeps bounded persistent history, and presents searchable entries with native previews in a floating panel. It skips pasteboard items marked concealed, transient, or auto-generated. Use ⇧⌘V to show history and ⌃⇧⌘5 to select a screen region. Selecting an entry restores it to the pasteboard and, with user-granted Accessibility access, pastes it into the previously active app. The menu-bar Clear History action removes local metadata and Pasteboard-owned image copies after confirmation without deleting referenced user files.
