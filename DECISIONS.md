# Architecture decisions

## 2026-07-22 — Native Swift
Decision: Swift 6 with SwiftUI and AppKit. Context: the utility requires deep macOS integration and low idle overhead. Alternatives: Electron, Tauri. Reason: native APIs, accessibility, and footprint. Consequences: macOS-only implementation.

## 2026-07-22 — AppKit panel with SwiftUI content
Decision: host SwiftUI views in an AppKit-managed panel. Context: a floating keyboard-driven panel needs window behaviors SwiftUI alone does not fully expose. Alternative: ordinary SwiftUI window. Consequence: explicit focus and lifecycle coordination.

## 2026-07-22 — Local-only persistence
Decision: no network or cloud path. Context: clipboard data is sensitive. Alternatives: sync or accounts. Reason: privacy and simplicity. Consequence: history remains per Mac.

## 2026-07-22 — External image payloads
Decision: keep image files outside the metadata database. Context: large blobs impair database maintenance. Alternative: database blobs. Consequence: cleanup must coordinate rows and files.

## 2026-07-22 — XcodeGen
Decision: commit `project.yml` and generate the Xcode project with XcodeGen. Context: reproducible reviewable project configuration. Alternative: hand-maintained pbxproj. Consequence: contributors install a development-only generator.

## 2026-07-22 — macOS 14 minimum
Decision: support macOS 14+. Context: modern SwiftUI APIs with a reasonable compatibility window. Alternative: older macOS. Consequence: earlier releases are unsupported.

## 2026-07-22 — SQLite metadata
Decision: use SQLite through native system libraries. Context: bounded searchable local history needs transactional persistence. Alternatives: flat JSON, Core Data. Reason: explicit schema and predictable cleanup. Consequence: migrations must be maintained.

The text-only milestone uses an atomic JSON file as a temporary, dependency-free store. It will migrate to the decided SQLite metadata store before mixed text, image, and file history is introduced.

## 2026-07-22 — Carbon hotkeys
Decision: use the system Carbon hotkey registration API behind a narrow adapter. Context: reliable global shortcuts without event taps. Alternatives: NSEvent monitors or a third-party package. Consequence: small legacy C API boundary, no runtime dependency.

## 2026-07-22 — Approved application icon and template menu-bar asset

Decision: retain the supplied PasteBoard logo as the immutable application-icon source and compile its standard macOS variants through an asset catalog. Use a separately rendered monochrome `doc.on.clipboard` SF Symbol as the temporary template menu-bar image.

Context: the full-color approved artwork is designed for the app bundle, Dock, Finder, application switcher, About panel, and settings, but is too detailed and contains a colored background unsuitable for the menu bar.

Alternatives considered: use the full icon everywhere, redraw the approved artwork, or continue using a SwiftUI system-image label without a committed menu-bar asset.

Reason: this preserves the approved visual identity exactly while giving macOS a legible template image that adapts automatically to light and dark appearances.

Consequences: the original and generated variants are committed product resources. Replacing the application icon requires explicit user direction. The temporary menu-bar fallback can be replaced only by a separately approved monochrome derivative.
