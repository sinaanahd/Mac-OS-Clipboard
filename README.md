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

The app monitors text and image clipboard changes locally, keeps bounded persistent history, and presents searchable entries and image thumbnails in a floating panel. Use ⇧⌘V or the menu-bar clipboard icon to show it. Selecting an entry restores it to the system pasteboard and, with user-granted Accessibility access, pastes it into the previously active app. File entries and region screenshots remain roadmap work.
