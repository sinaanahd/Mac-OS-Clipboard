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

## 2026-07-22 — SQLite metadata (superseded 2026-07-23)
Decision: SQLite was initially planned but is not the implemented storage mechanism. Context: the bounded local model remains small and does not need a database migration for 1.2. Alternatives: SQLite and Core Data. Reason for superseding: coalesced atomic JSON is simpler, preserves existing history, and meets current reliability needs. Consequences: documentation describes structured metadata rather than a database; a future database migration requires new evidence and an explicit migration plan.

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

## 2026-07-23 — Publish app screenshots to the general pasteboard

Decision: after a successful app-initiated region capture is validated and imported, publish its PNG representation to the general macOS pasteboard.

Context: users expect to press Command-V immediately after taking a screenshot, matching common native and Windows snipping workflows.

Alternatives considered: retain history-only capture, require reopening history and selecting the image, or synthesize an automatic paste event.

Reason: placing the PNG on the pasteboard enables explicit user-controlled Command-V without requiring Accessibility permission or injecting input. Existing content hashing suppresses the monitor's duplicate observation.

Consequences: a successful capture replaces the current general pasteboard contents; cancelled, invalid, and failed captures leave it unchanged. The image remains local and is exposed only through the standard macOS pasteboard.

## 2026-07-23 — UserDefaults for typed preferences

Decision: persist non-sensitive application preferences through a centralized typed `AppSettings` model backed by `UserDefaults`.

Context: Pasteboard 1.2 requires runtime-personalizable shortcuts, limits, behavior, panel placement, and exclusions while preserving the existing JSON clipboard-history file and image payloads.

Alternatives considered: storing preferences inside clipboard-history metadata, adding a database solely for preferences, or scattering `@AppStorage` properties across views.

Reason: `UserDefaults` is the native lightweight preference store, while a single observable model provides validation, dependency injection, resets, and upgrade-safe defaults.

Consequences: only configuration values and bundle identifiers enter `UserDefaults`; clipboard contents, history metadata, screenshots, and image payloads remain in Application Support.

## 2026-07-23 — Pinned entries excluded from limits

Decision: both configured counts apply only to unpinned entries. Context: pins promise retention. Alternatives considered: count pins, separate favorites, or silently prune them. Reason: user intent must survive automatic cleanup. Consequences: total entries and storage can exceed configured limits; clear-all remains an explicit destructive action.

## 2026-07-23 — High custom limits with warnings

Decision: accept history values through 100,000 and image values through 10,000, while warning above 1,000 and 500 respectively. Context: power users need flexibility. Alternatives considered: hard recommendation caps or unlimited values. Reason: bounded flexibility is safer and less arbitrary. Consequences: performance above recommendations is not guaranteed, and reductions confirm exact removals.

## 2026-07-23 — Progressive macOS 26 enhancement

Decision: use availability-checked macOS 26 APIs and preserve macOS 14 material fallbacks. Context: the app should feel current without raising its minimum deployment target. Alternatives considered: macOS 26-only deployment or a fully custom appearance. Reason: progressive native controls preserve compatibility and accessibility. Consequences: visual details differ by OS while behavior remains consistent.

## 2026-07-23 — Liquid Glass only for functional surfaces

Decision: apply glass to the header/search and transient confirmation HUD, not content rows. Context: repeated glass reduces hierarchy and readability. Alternatives considered: glass on every row or no new-system treatment. Reason: restrained functional grouping follows platform guidance. Consequences: clipboard content remains a high-contrast layer.

## 2026-07-23 — System accessibility preferences control effects

Decision: follow Reduce Motion, Reduced Transparency, and Increased Contrast rather than duplicating those settings. Context: system preferences are authoritative. Alternatives considered: app-specific accessibility toggles. Reason: native controls and materials already adapt consistently. Consequences: movement becomes short fades under Reduce Motion and no functionality depends on transparency.

## 2026-07-23 — Local DMG is the required distribution

Decision: make a credential-free unsigned DMG the required private distribution artifact. Context: Apple Developer Program access is not assumed. Alternatives considered: App Store-only delivery or requiring Developer ID. Reason: a local package is reproducible without paid services. Consequences: recipients may need the documented Open Anyway flow and must verify sender/checksum.

## 2026-07-23 — Developer ID distribution is optional

Decision: isolate signing and notarization in a credential-gated script using hardened runtime and `notarytool`. Context: credentials may not exist and must never enter source control. Alternatives considered: mixing signing into the local build. Reason: missing credentials must not break development or local release. Consequences: notarization status is reported honestly and the local DMG remains available.

## 2026-07-23 — Versioned DMGs are retained in Git

Decision: commit checksum-verified, versioned DMGs and matching checksum files under `dist/`. Context: repository visitors need access to earlier working versions when a newer release has a regression. Alternatives considered: ignoring all build artifacts, keeping only the latest DMG, or using GitHub Releases exclusively. Reason: the existing archive is small and direct repository visibility makes rollback straightforward. Consequences: repository size grows with every retained release, each artifact must be verified before commit, unsigned status must remain explicit, and temporary builds, unpackaged apps, credentials, certificates, and signing material remain prohibited.
