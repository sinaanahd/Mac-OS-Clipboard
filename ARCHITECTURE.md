# Architecture

Pasteboard is a single native macOS application target plus unit tests. SwiftUI owns settings and panel content; AppKit will own pasteboard polling, non-activating panel behavior, global event integration, and permission-sensitive system actions.

Feature folders separate App composition, Models, Clipboard, Storage, Hotkeys, Panel, Screenshot, Paste, Privacy, Settings, Resources, and Utilities as each becomes real. Configuration and visual constants are centralized in `Utilities`. Runtime metadata will use SQLite through native system APIs, while images remain atomic files under Application Support. Services will expose narrow protocols so pasteboard, storage, clock, and permission behavior can be tested without accessing user data.
