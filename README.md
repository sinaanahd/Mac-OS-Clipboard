# Pasteboard

Pasteboard is a native, lightweight, local-only macOS clipboard history and screenshot utility built with SwiftUI and AppKit.

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

The app monitors text, image, and Finder file selections locally, keeps bounded persistent history, and presents searchable entries with native previews in a floating panel. Use ⇧⌘V to show history and ⌃⇧⌘5 to select a screen region. Selecting an entry restores it to the pasteboard and, with user-granted Accessibility access, pastes it into the previously active app.
