# Manual testing

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

1. Press Shift-Command-V from another application and verify the panel appears near the pointer.
2. Press the shortcut again and verify the panel hides.
3. Verify the search field accepts keyboard input and the panel dismisses after restoring an entry or losing focus.
4. Verify the menu-bar clipboard item can show the panel and quit the app.
5. Verify the Pasteboard icon, product name, and Clipboard History label remain fixed above search while the list scrolls.
6. Scroll down, copy a new matching item, and verify the list returns to the new first row without placing it behind search.

## Automatic paste

1. Without Accessibility permission, select an entry and verify it is copied but not pasted.
2. Verify Pasteboard explains why access is needed before macOS displays its permission prompt.
3. Grant access in Privacy & Security > Accessibility, reopen the panel from a text editor, and select an entry.
4. Verify the editor reactivates and receives exactly one paste operation.
5. Deny or revoke access and verify manual paste continues to work without repeated unsolicited prompts.

## Region screenshots

1. Without Screen Recording access, press Control-Shift-Command-5 and verify Pasteboard explains why access is needed before macOS prompts.
2. Grant access, invoke the shortcut again, drag a region, and verify one image entry appears.
3. Press Escape during selection and verify no history entry or temporary file remains.
4. Capture on each connected display and verify correct pixels and native scaling.
5. Restore the captured entry and paste it into Preview or Notes.

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
