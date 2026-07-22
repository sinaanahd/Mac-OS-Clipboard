# Architecture

Pasteboard is one native Swift 6 macOS application target plus XCTest tests. XcodeGen owns the reproducible project definition. The deployment target remains macOS 14 and the current build is verified on Apple Silicon.

SwiftUI renders the history and five Settings panes. AppKit owns the nonactivating floating panel, menu-bar integration, system search field, application discovery, global window behavior, and permission-sensitive alerts. Carbon provides dependency-free global hotkey registration behind `ShortcutCoordinator`; replacement registration succeeds before the previous shortcut is released.

`AppSettings` is the typed, validated `UserDefaults` preference source. Clipboard content never enters `UserDefaults`. `AppDelegate` coordinates live monitoring, limits, expiration, `SMAppService`, screenshot behavior, panel placement, and feedback. Services use narrow protocols or injectable factories for permission, event-posting, persistence, image storage, and hotkey tests.

History metadata lives at `~/Library/Application Support/Pasteboard/clipboard-history.json`. A dedicated serial utility queue coalesces rapid saves and performs atomic file replacement; normal termination flushes pending state. Original PNG payloads live in `Images/`. Pruning and clearing remove only Pasteboard-owned payloads and never original Finder files. Pinned entries sort first and bypass automatic count and expiration cleanup.

Image rows request cached, downsampled thumbnails asynchronously; original PNGs remain untouched for paste restoration. Region capture delegates selection to `/usr/sbin/screencapture -i`, waits for a stable valid PNG, then applies the selected history/copy behavior and deletes its temporary file.

The history panel uses one functional header/search surface. macOS 26 receives native `glassEffect`; macOS 14 and 15 receive semantic system material. Content rows do not receive decorative glass. SwiftUI/AppKit animations use centralized short durations and replace movement with fades when Reduce Motion is enabled.

Local distribution is a compressed unsigned DMG containing `Pasteboard.app` and an Applications link. Optional Developer ID signing, hardened runtime, notarization, stapling, and assessment are isolated in a credential-gated script and never affect Debug, tests, or local packages.
