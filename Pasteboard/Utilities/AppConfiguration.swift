import AppKit
import Foundation

struct KeyboardShortcut: Equatable, Sendable {
    let key: String
    let modifiers: NSEvent.ModifierFlags

    var displayName: String {
        let symbols = [
            modifiers.contains(.control) ? "⌃" : "",
            modifiers.contains(.option) ? "⌥" : "",
            modifiers.contains(.shift) ? "⇧" : "",
            modifiers.contains(.command) ? "⌘" : ""
        ].joined()
        return symbols + key.uppercased()
    }
}

enum ExpirationPolicy: Equatable, Sendable {
    case never
    case after(TimeInterval)
}

enum AppConfiguration {
    static let productName = "Pasteboard"
    static let bundleIdentifier = "com.sinaanahd.Pasteboard"
    static let defaultHistoryShortcut = KeyboardShortcut(key: "v", modifiers: [.command, .shift])
    static let defaultScreenshotShortcut = KeyboardShortcut(key: "5", modifiers: [.command, .shift])
    static let defaultHistoryLimit = 200
    static let defaultImageLimit = 50
    static let clipboardPollingInterval: TimeInterval = 0.5
    static let applicationSupportDirectoryName = "Pasteboard"
    static let databaseFilename = "clipboard-history.sqlite"
    static let screenshotFilenameFormat = "Pasteboard-%Y%m%d-%H%M%S.png"
    static let defaultExpirationPolicy: ExpirationPolicy = .never
    static let panelSize = NSSize(width: 420, height: 560)
}
