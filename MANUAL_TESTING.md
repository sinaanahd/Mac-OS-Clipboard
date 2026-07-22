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

Accessibility-driven paste and Screen Recording flows are not yet implemented or manually testable.
