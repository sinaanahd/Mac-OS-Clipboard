# Architecture

Pasteboard is a single native macOS application target plus unit tests. SwiftUI owns settings and panel content; AppKit will own pasteboard polling, non-activating panel behavior, global event integration, and permission-sensitive system actions.

Feature folders separate App composition, Models, Clipboard, Storage, Hotkeys, Panel, Screenshot, Paste, Privacy, Settings, Resources, and Utilities as each becomes real. Configuration and visual constants are centralized in `Utilities`. Runtime metadata will use SQLite through native system APIs, while images remain atomic files under Application Support. Services will expose narrow protocols so pasteboard, storage, clock, and permission behavior can be tested without accessing user data.

The approved application-icon source is retained under `Design/Source`. Reproducible macOS icon representations and the monochrome template menu-bar image live in `Pasteboard/Resources/Assets.xcassets`; XcodeGen includes the catalog in the application target and selects `AppIcon` at build time. The current menu-bar image is a temporary native `doc.on.clipboard` SF Symbol rendering until an explicitly approved custom monochrome derivative is supplied.
