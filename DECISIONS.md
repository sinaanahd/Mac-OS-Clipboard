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

## 2026-07-22 — Carbon hotkeys
Decision: use the system Carbon hotkey registration API behind a narrow adapter. Context: reliable global shortcuts without event taps. Alternatives: NSEvent monitors or a third-party package. Consequence: small legacy C API boundary, no runtime dependency.
