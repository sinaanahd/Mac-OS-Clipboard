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

The app monitors plain-text clipboard changes locally, keeps a bounded persistent history, and presents searchable entries in a floating panel. Use ⇧⌘V or the menu-bar clipboard icon to show it. Selecting an entry restores it to the system pasteboard. Automatic paste, images, files, and screenshots remain roadmap work.
