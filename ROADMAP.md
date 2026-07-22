# Roadmap

States: Not started, In progress, Blocked, Completed.

- [x] Project foundation — Completed
  - [x] Import the approved PasteBoard application icon
  - [x] Generate the required macOS icon variants
  - [x] Configure the asset catalog to use AppIcon
  - [x] Create a separate monochrome menu-bar template icon
  - [x] Verify the icon in Finder, the Dock, application switching, and build output
- [x] Text clipboard history — Completed
- [x] Floating history panel — Completed
- [x] Automatic paste — Completed
- [x] Image and screenshot history — Completed
- [x] File history — Completed
- [x] Region screenshot capture — Completed
- [x] Privacy and cleanup — Completed
- [ ] Polish and testing — In progress
  - [x] Add a branded history header and keep newly captured entries visible
  - [x] Tighten panel header spacing and replace continuous relative-time updates
  - [x] Add persistent pinning for individual history entries
  - [x] Adopt Option-V history access and a delay-tolerant native screenshot workflow
  - [x] Add a native clear button to history search
  - [x] Anchor empty states at the top and make captured screenshots immediately pasteable
- [ ] Packaging and distribution — In progress
  - [x] Establish version 1.0.0 and display the bundle version in the history panel
  - [x] Advance the substantial interaction update to version 1.1.0
  - [x] Release the search clear-button refinement as version 1.1.1
  - [x] Release empty-state and screenshot-paste fixes as version 1.1.2
  - [ ] Build an unsigned local Release application
  - [ ] Package `Pasteboard.app` and an Applications link in a compressed DMG
  - [ ] Generate and verify the DMG SHA-256 checksum
  - [ ] Document trusted local installation and Gatekeeper limitations
  - [ ] Add an optional Developer ID and notarization workflow
- [x] Settings architecture — Completed
- [x] Shortcut personalization — Completed
- [x] History and storage personalization — Completed
- [x] macOS 26 visual refinement — Completed
- [x] Accessible animations — Completed
- [ ] Release stability corrections — In progress
- [ ] Local DMG packaging — Not started
- [ ] Optional signed distribution — Not started
- [ ] Release validation — Not started

## Pasteboard 1.2.0 baseline

- [x] Repository and required documentation audited on 2026-07-23
- [x] Xcode project regenerated with XcodeGen 2.46.0
- [x] Existing 1.1.2 Debug build succeeded on Apple Silicon
- [x] Existing 1.1.2 automated suite passed: 27 tests, 0 failures
- [ ] Existing manual polish checklist completed on macOS 14, 15, and 26 where available
