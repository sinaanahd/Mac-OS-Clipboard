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

## 2026-07-22 — Persistent pins bypass automatic cleanup

Decision: store pin state with each clipboard entry, sort pinned entries above regular history, and exempt them from automatic history limits and expiration.

Context: users need an explicit way to keep important entries available even as transient history rotates.

Alternatives considered: visual-only pins that do not affect cleanup, a separate favorites database, or allowing configured limits to delete pinned entries.

Reason: a pin should provide a predictable retention guarantee while remaining local, simple, and reversible.

Consequences: pinned entries and owned image payloads may increase storage beyond configured automatic limits. Users retain control through unpin, delete, and confirmed Clear History actions.

## 2026-07-22 — Semantic versioning from a 1.0.0 baseline

Decision: establish 1.0.0 as the initial marketing version, store it in the reproducible XcodeGen configuration, and display the compiled bundle value in the history panel.

Context: published builds need an identifiable version and a predictable rule for future releases.

Alternatives considered: hard-code a UI-only version, use build numbers alone, or increment versions without a documented policy.

Reason: bundle-backed semantic versioning keeps Finder, About, build metadata, and the in-app label consistent.

Consequences: every ordinary publishable change after 1.0.0 increments the patch component; substantial feature releases increment the minor component and reset patch to zero. Major-version changes require explicit user direction.

## 2026-07-23 — Option-V and native delayed screenshot import

Decision: use Option-V for clipboard history and Option-Shift-4 for region capture. Continue delegating selection to macOS's built-in `screencapture -i` process, but wait asynchronously for a stable PNG before import.

Context: the primary interaction should substitute for the familiar Windows+V habit on a Mac, and native screenshot output may not be safely readable at the first filesystem observation.

Alternatives considered: retain Command-Shift-V, imitate the selector with a custom overlay, intercept Apple's Command-Shift-4 shortcut, or read the output file only once.

Reason: Option-V is compact and memorable, while a distinct Option-Shift-4 shortcut avoids overriding Apple's system shortcut. Reusing the native selector preserves expected macOS behavior, and bounded stability polling handles delayed saves without blocking the main thread.

Consequences: Option-V and Option-Shift-4 are globally consumed while Pasteboard runs. Capture waits up to five seconds after successful selector completion, rejects non-PNG output, cleans up its temporary file, and permits only one active capture at a time. This substantial interaction change advances the app to version 1.1.0.
