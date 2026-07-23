# Manual testing

Record release-specific results in `RELEASE_VALIDATION.md`. For each completed manual group, include the date, exact macOS build, architecture, tester, and concise evidence. Leave unavailable operating systems as “Not run”; do not infer a manual pass from CI.

## Foundation

1. Generate and build using the README commands.
2. Launch Pasteboard and verify the native empty state is visible in light and dark mode.
3. Open Settings and verify configured shortcuts and history limit are displayed.
4. Verify VoiceOver announces the empty state meaningfully.

## Text history

1. Copy several text values and verify newest-first appearance within one second.
2. Copy the same value twice and verify no consecutive duplicate appears.
3. Search case-insensitively, delete an item, and relaunch to verify persistence.
4. Select an item and paste elsewhere to verify it was restored to the system pasteboard.

## Floating panel

1. Press Option-V from another application and verify the panel appears near the pointer.
2. Press the shortcut again and verify the panel hides.
3. Verify the search field accepts keyboard input and the panel dismisses after restoring an entry or losing focus.
4. Verify the menu-bar clipboard item can show the panel and quit the app.
5. Verify the Pasteboard icon, product name, and Clipboard History label remain fixed above search while the list scrolls.
6. Scroll down, copy a new matching item, and verify the list returns to the new first row without placing it behind search.
7. Verify only a minimal inset remains above the Pasteboard icon and name.
8. Leave the panel open and verify relative ages remain unchanged; close and reopen it and verify they recalculate.
9. Pin text, image, and file entries and verify they move above unpinned history without restoring their content.
10. Relaunch Pasteboard and verify pinned entries remain pinned and ordered newest-first within the pinned section.
11. Unpin an entry and verify it returns to chronological position among regular history.
12. Exceed history and image limits and run expiration cleanup; verify pinned entries remain until explicitly deleted or cleared.
13. Verify `Version 1.2.3` appears at the top-right of the header and matches About Pasteboard and the built app's bundle metadata.
14. Enter a search query, click the native clear button inside the field, and verify the complete history immediately returns.
15. Clear history or search for a missing value and verify the empty state stays directly below search instead of centering the entire panel content.
16. Keep Settings open, show clipboard history, then focus Settings; verify the panel dismisses cleanly without a re-entrant `resignKey` error.
17. Open About and verify the copyright reads `Copyright © 2026 Sina Anahid`.

## Pasteboard 1.2 settings and release checklist

Prefer a clean or secondary macOS account. Do not mark an OS-specific item complete unless tested on that OS.

The GitHub Actions matrix checks compilation and unit tests on macOS 14, 15, and 26. It does not replace the permission, Gatekeeper, accessibility, visual, multi-display, or end-to-end interaction checks below.

### Settings and personalization

1. Change every setting, relaunch, and verify it persists; then use Reset All Settings and verify defaults.
2. Verify malformed and out-of-range custom limits are rejected or safely normalized.
3. Enter history values above 1,000 and image values above 500; verify the performance warning appears and accepted values remain usable.
4. Reduce each limit below the current count; verify the confirmation gives the exact removal count, oldest unpinned entries disappear, pins survive, owned PNGs are removed, and Finder originals remain.
5. Increase a limit and verify removed entries are not restored.
6. Exercise each expiration option and verify pins remain.
7. Toggle launch at login and verify System Settings/`SMAppService` state, including denial or approval-required feedback.
8. Disable automatic paste; select an item and verify it is copied, the panel closes, and no Accessibility prompt or synthetic Command-V occurs.
9. Pause monitoring from Settings and the menu; verify existing history and history access remain, no new entries appear, and resuming works.
10. Test near-pointer, active-screen center, and remembered panel position on multiple displays; verify the panel stays within the visible frame.

### Shortcuts

1. Verify defaults ⌥V and ⌥⇧4 invoke only their intended action.
2. Record letter, number, punctuation, arrow, and practical function-key combinations; verify symbol formatting and immediate operation without restart.
3. Press Escape while recording and verify no change; press Delete and verify removal; Reset restores each default.
4. Try a modifier-only, bare, unsupported, duplicate, and known system-reserved combination; verify inline error and the previous shortcut remains active.
5. Relaunch and verify custom shortcuts persist and distinct hotkey routing remains correct.

### Screenshots and privacy

1. Test “history and clipboard,” “history only,” and “clipboard only”; verify exactly the selected destinations and matching confirmation wording.
2. Cancel region selection and verify history and the general pasteboard do not change.
3. Exclude a running app, copy text/image/file content while it is frontmost, and verify Pasteboard does not record it; remove the exclusion and verify capture resumes.
4. Verify concealed, transient, and auto-generated pasteboard types remain skipped.
5. Compare displayed metadata, image, and total storage with files under Application Support; verify calculation does not stall Settings.
6. Clear unpinned history and verify pins remain. Clear all and verify pins and owned payloads are removed only after confirmation.

### Design, animation, and accessibility

1. On macOS 26, verify glass is limited to functional header/search and temporary feedback surfaces; content rows, text, and thumbnails remain legible.
2. On macOS 14 or 15, verify fallback materials render and no unavailable-API crash occurs.
3. Verify panel opening/closing, insertion, pinning, deletion, and search transitions are short and do not delay actions.
4. Enable Reduce Motion and verify positional movement becomes fades. Enable Reduced Transparency and Increased Contrast and verify grouping and controls remain readable.
5. Check keyboard-only Settings and history navigation, VoiceOver labels, focus rings, large text tolerance, and that color is not the sole status signal.
6. Focus the history list and verify Up/Down changes the selected row, Return restores it, Space toggles its pin, and Delete removes it without requiring a pointer.

### DMG

1. From a clean checkout, run `./scripts/build-local-dmg.sh`.
2. Run `hdiutil verify`, recompute SHA-256, and check the generated checksum file.
3. Mount the DMG; verify it contains only `Pasteboard.app` and `Applications -> /Applications`, with no clipboard history or credentials.
4. Drag to Applications, launch, and verify the documented Gatekeeper Open Anyway flow for the unsigned build without disabling security.
5. Grant only needed permissions, test history and screenshots, eject/remount, and repeat launch.
6. Run the notarized workflow only when valid Developer ID and notary credentials exist; verify signing, stapling, and Gatekeeper results separately.
## Automatic paste

1. Without Accessibility permission, select an entry and verify it is copied but not pasted.
2. Verify Pasteboard explains why access is needed before macOS displays its permission prompt.
3. Grant access in Privacy & Security > Accessibility, reopen the panel from a text editor, and select an entry.
4. Verify the editor reactivates and receives exactly one paste operation.
5. Deny or revoke access and verify manual paste continues to work without repeated unsolicited prompts.

## Region screenshots

1. Without Screen Recording access, press Option-Shift-4 and verify Pasteboard explains why access is needed before macOS prompts.
2. Grant access, invoke the shortcut again, drag a region, and verify one image entry appears.
3. Press Escape during selection and verify no history entry or temporary file remains.
4. Capture on each connected display and verify correct pixels and native scaling.
5. Restore the captured entry and paste it into Preview or Notes.
6. Complete a slow region selection and verify Pasteboard waits for the PNG to finish saving before adding exactly one image entry.
7. Cancel the built-in selector and verify no history entry or temporary file remains.
8. Complete a capture, switch to an image-capable application, press Command-V, and verify the captured image pastes immediately.

## Image history

1. Copy an image and a macOS screenshot and verify thumbnails appear newest first.
2. Copy the same image twice and verify no consecutive duplicate is added.
3. Select an image entry and paste into Preview or Notes.
4. Delete image entries and verify their owned files disappear from Application Support/Pasteboard/Images.
5. Exceed the configured image limit and verify older image payloads are removed while text entries remain.

## File history

1. Copy one file and then multiple files in Finder; verify each selection becomes one history entry.
2. Verify file entries show native icons and searchable filenames rather than image-preview clipboard data.
3. Restore a file entry and paste it into another Finder folder or an application accepting files.
4. Move or delete an original file and verify Pasteboard remains stable and does not delete or recreate user files.

## Privacy and cleanup

1. Copy from an application that marks password-manager content as concealed and verify the item does not appear in history.
2. Publish test pasteboard content marked transient or auto-generated and verify it is skipped while ordinary text remains capturable.
3. Choose Clear History from the menu bar, cancel once, and verify entries remain.
4. Confirm Clear History and verify entries and Pasteboard-owned images are removed after relaunch.
5. Verify original Finder files referenced by cleared file entries still exist unchanged.
6. Place an unreferenced test image in Application Support/Pasteboard/Images, relaunch, and verify only the orphan is removed.

## Application and menu-bar icons

1. Build the Debug application and verify the asset catalog reports no warnings or missing icon slots.
2. Locate the built app in Finder and verify it displays the approved PasteBoard icon.
3. Launch the app and verify the approved icon appears in the Dock and application switcher when the app is configured to appear there.
4. Open About Pasteboard and Settings and verify the approved icon appears without cropping, stretching, or added masking.
5. Verify the menu-bar icon is a readable monochrome clipboard/history silhouette rather than the colored application-icon square.
6. Check the menu-bar icon in both light and dark appearances and verify template rendering adapts its color.
