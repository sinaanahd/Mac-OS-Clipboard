# Product specification

## Product vision

Pasteboard is a fast, native, local-only macOS utility that makes recent clipboard items and region screenshots easy to find and reuse without sending data off-device.

## Visual identity

The supplied PasteBoard clipboard-and-history artwork is the approved application icon. Preserve it without redesign, recoloring, cropping, or replacement unless the user explicitly requests a visual-identity change. The menu bar uses a separate monochrome template image so it remains legible in light and dark appearances.

## User workflows

Users copy content normally, press Option-V as a macOS analogue to the Windows+V habit, search or navigate recent items, and select an item to restore it to the pasteboard and optionally paste it into the previously active application. Users press Option-Shift-4 to invoke macOS's built-in interactive region selector and retain the result locally.

The history panel displays the bundle marketing version at the top-right. The first publishable baseline is version 1.0.0; the customizable personal release is version 1.2.0. Subsequent ordinary publishable changes increment the patch number, while substantial feature releases increment the minor number and reset patch to zero.

## Clipboard history

Record supported text, image, and file clipboard entries; order pinned entries first and remaining entries newest first; avoid consecutive duplicates; preserve useful metadata; enforce configurable type and total limits; support pinning, unpinning, deletion, and clearing. Pinned entries persist across launches and are exempt from automatic limits and expiration until explicitly unpinned, deleted, or cleared. Never capture known-sensitive or excluded content where macOS exposes an appropriate signal.

## Screenshot capture

Invoke the built-in macOS interactive region-selection workflow, wait for its output PNG to finish saving before import, store captures locally, and place successful captures on the macOS pasteboard for immediate Command-V. Display thumbnails, copy or reuse captures, use predictable unique filenames, and explain Screen Recording permission when required. Cancellation and delayed or missing output must fail safely without changing the pasteboard or leaving temporary files.

## Search and navigation

Provide a compact branded header with minimal top inset above the search field, incremental text search with a native in-field clear button, keyboard navigation, selection, dismissal, deletion, and clear empty states anchored directly below search rather than centered in the panel. When the history list is focused, Up and Down select entries, Return restores the selection through the panel's native keyboard-equivalent path, Space pins or unpins it, and Delete removes it. Return in the search field must not restore a stale row. The newest matching entry must remain visible when history updates, even when the list was previously scrolled. Relative entry ages are snapshots recalculated when history opens or a new item arrives, not continuously refreshed. Search should cover safe textual metadata without OCR in the initial release.

## Persistence

Persist metadata as coalesced, atomically replaced structured JSON under Application Support. Store image payloads as separate files outside metadata. Recover safely from missing files and interrupted writes, flush pending state at normal termination, and apply user limits and expiration during cleanup.

## Privacy

No accounts, cloud sync, telemetry, advertising, or network transmission. Never log complete clipboard content. Provide clear-history and expiration controls. Keep runtime data out of the repository and backups where practical.

## Permissions

Clipboard observation should use public pasteboard APIs. Automatic paste may require Accessibility permission; region capture may require Screen Recording permission. Explain and request each permission only when its feature is used, and degrade gracefully when denied.

## Settings

Provide native General, Features, Shortcuts, Privacy & Storage, and About panes backed by typed local preferences. Allow editing history and screenshot shortcuts, history and image limits, expiration, launch behavior, automatic paste behavior, monitoring, panel placement, screenshot completion, excluded applications, and cleanup actions. Validate stored values and shortcut conflicts, support individual and complete resets, and preserve existing history and pins during upgrades.

## Performance

Remain responsive with 200 history entries, avoid loading full-size images into list rows, perform I/O off the main actor, and keep polling and idle resource use low.

## Accessibility

Support VoiceOver labels, keyboard-only workflows, focus visibility, Dynamic Type where applicable, reduced motion, increased contrast, and light/dark appearances.

## Acceptance criteria

- Native macOS app builds and tests from the command line on Apple Silicon.
- Text, image, and file entries can be captured, searched, restored, deleted, and retained across launches.
- Consecutive duplicates are suppressed and configured limits are enforced.
- Every history entry can be pinned or unpinned, and pinned entries remain above regular history.
- The floating panel and its primary actions are keyboard accessible.
- Automatic paste and region screenshots explain permissions and fail safely.
- Clearing history removes metadata and owned payload files.
- No clipboard content or screenshots leave the device.

## Future features

Richer previews, optional OCR, user-defined transformations, multiple collections, import/export, and carefully designed encrypted sync are future considerations only.

## Explicit non-goals

No Electron/web UI, accounts, cloud sync, collaboration, cross-platform support, password-manager replacement, clipboard content analytics, remote APIs, or bypassing macOS security controls.
