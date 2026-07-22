# Changelog

## Unreleased

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
