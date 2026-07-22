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

## Automatic paste

1. Without Accessibility permission, select an entry and verify it is copied but not pasted.
2. Verify Pasteboard explains why access is needed before macOS displays its permission prompt.
3. Grant access in Privacy & Security > Accessibility, reopen the panel from a text editor, and select an entry.
4. Verify the editor reactivates and receives exactly one paste operation.
5. Deny or revoke access and verify manual paste continues to work without repeated unsolicited prompts.

Screen Recording flows are not yet implemented or manually testable.

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
