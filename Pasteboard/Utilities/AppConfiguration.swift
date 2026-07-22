import AppKit
import Carbon.HIToolbox
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

    var carbonKeyCode: UInt32? {
        switch key.lowercased() {
        case "v": UInt32(kVK_ANSI_V)
        case "4": UInt32(kVK_ANSI_4)
        default: nil
        }
    }

    var carbonModifiers: UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) { result |= UInt32(cmdKey) }
        if modifiers.contains(.option) { result |= UInt32(optionKey) }
        if modifiers.contains(.control) { result |= UInt32(controlKey) }
        if modifiers.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }
}

enum ExpirationPolicy: Equatable, Sendable {
    case never
    case after(TimeInterval)
}

enum AppConfiguration {
    static let productName = "Pasteboard"
    static let bundleIdentifier = "com.sinaanahd.Pasteboard"
    static let developmentVersionFallback = "1.1.2"
    static var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? developmentVersionFallback
    }
    static let defaultHistoryShortcut = KeyboardShortcut(key: "v", modifiers: [.option])
    static let defaultScreenshotShortcut = KeyboardShortcut(key: "4", modifiers: [.option, .shift])
    static let defaultHistoryLimit = 200
    static let defaultImageLimit = 50
    static let clipboardPollingInterval: TimeInterval = 0.5
    static let defaultAutomaticPasteEnabled = true
    static let automaticPasteDelay: TimeInterval = 0.12
    static let applicationSupportDirectoryName = "Pasteboard"
    static let databaseFilename = "clipboard-history.sqlite"
    static let interimTextHistoryFilename = "clipboard-history.json"
    static let imagePayloadDirectoryName = "Images"
    static let screenshotFilenamePrefix = "Pasteboard"
    static let screenshotFilenameDateFormat = "yyyyMMdd-HHmmss"
    static let screenshotImportTimeout: Duration = .seconds(5)
    static let screenshotImportPollInterval: Duration = .milliseconds(100)
    static let defaultExpirationPolicy: ExpirationPolicy = .never
    static let panelSize = NSSize(width: 420, height: 560)
}
