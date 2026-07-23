# Changelog

## Unreleased

- Corrected the About pane and bundle copyright name to Sina Anahid; released as version 1.2.2 build 7.
- Fixed a re-entrant panel key-window transition when Settings and clipboard history were open together; released as version 1.2.1 build 6.
- Began Pasteboard 1.2.0 with persistent typed preferences and native General, Features, Shortcuts, Privacy & Storage, and About settings panes.
- Added native global-shortcut recording, validation, removal/reset, and live registration with conflict feedback.
- Applied monitoring, limits, expiration, panel position, screenshot behavior, automatic paste, and launch-at-login preferences at runtime.
- Added asynchronous local storage reporting, safe clear-unpinned/all actions, Finder access, application exclusions, and coordinated settings reset.
- Coalesced atomic history writes off the main thread, confirmed target focus before one automatic paste event, and downsampled thumbnails asynchronously.
- Refined the native macOS 26 functional surface and added short, accessibility-aware interaction animations and confirmation feedback.
- Added credential-free local DMG packaging, an isolated optional notarization workflow, and accurate release documentation.
- Verified a clean universal Release build, mounted DMG contents, SHA-256 integrity, and 53 passing automated tests for 1.2.0 build 5.
- Kept empty and no-result history states anchored below search instead of vertically centering the panel.
- Copied successful app-initiated screenshots to the macOS pasteboard for immediate Command-V in version 1.1.2.
- Added the native in-field clear button to history search for version 1.1.1.
- Changed history to Option-V and region capture to Option-Shift-4 for version 1.1.0.
- Hardened built-in macOS region capture by waiting for a stable PNG before importing it.
- Established version 1.0.0 and added the bundle version to the history-panel header.
- Added persistent pin and unpin controls; pinned entries stay above regular history and are protected from automatic limits and expiration.
- Reduced empty space above the history header and changed relative ages to refresh only on panel opens and new captures.
- Added a compact Pasteboard logo and name above history search.
- Fixed newly captured entries appearing above the visible list when history was scrolled.
- Added the approved PasteBoard application icon, standard macOS asset variants, About and Settings presentation, and a monochrome template menu-bar fallback.

- Added the native macOS application and unit-test foundation.
- Added centralized product and visual configuration.
- Added project, privacy, architecture, testing, and contribution documentation.
- Added local text clipboard monitoring, bounded history, duplicate suppression, search, deletion, restoration, and persistence.
- Added a menu-bar entry and floating history panel toggled with the native global history shortcut.
- Added permission-gated automatic paste into the previously active application.
- Added bounded image clipboard history with local file payloads, thumbnails, restoration, duplicate suppression, and cleanup.
- Added Finder file-selection history with native icons, filename search, deduplication, and file URL restoration.
- Added native interactive region screenshots with a global shortcut, permission explanation, local import, and temporary-file cleanup.
- Fixed global hotkey routing so the history shortcut cannot trigger region capture.
- Fixed history panel ordering so the global shortcut brings it above other apps and full-screen windows.
- Fixed Carbon event propagation so each global shortcut reaches its matching handler.
- Added filtering for concealed, transient, and auto-generated pasteboard content.
- Added confirmed history clearing, expiration cleanup support, and removal of orphaned Pasteboard-owned image files.
