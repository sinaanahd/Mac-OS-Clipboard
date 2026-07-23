import AppKit
import Carbon.HIToolbox
import Foundation

struct KeyboardShortcut: Codable, Equatable, Sendable {
    private static let supportedModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
    let keyCode: UInt32
    private let modifierRawValue: UInt

    init(key: String, modifiers: NSEvent.ModifierFlags) {
        guard let keyCode = Self.keyCodesByName[key.lowercased()] else {
            preconditionFailure("Unsupported configured shortcut key: \(key)")
        }
        self.keyCode = keyCode
        modifierRawValue = modifiers.intersection(Self.supportedModifiers).rawValue
    }

    init?(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        guard Self.keyNamesByCode[keyCode] != nil else { return nil }
        self.keyCode = keyCode
        modifierRawValue = modifiers.intersection(Self.supportedModifiers).rawValue
    }

    var modifiers: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifierRawValue) }

    var displayName: String {
        let symbols = [
            modifiers.contains(.control) ? "⌃" : "",
            modifiers.contains(.option) ? "⌥" : "",
            modifiers.contains(.shift) ? "⇧" : "",
            modifiers.contains(.command) ? "⌘" : ""
        ].joined()
        return symbols + (Self.keyNamesByCode[keyCode] ?? "?").uppercased()
    }

    var carbonKeyCode: UInt32? { Self.keyNamesByCode[keyCode] == nil ? nil : keyCode }

    var carbonModifiers: UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) { result |= UInt32(cmdKey) }
        if modifiers.contains(.option) { result |= UInt32(optionKey) }
        if modifiers.contains(.control) { result |= UInt32(controlKey) }
        if modifiers.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }

    var isStructurallyValid: Bool {
        carbonKeyCode != nil && modifierRawValue != 0
            && modifierRawValue & ~Self.supportedModifiers.rawValue == 0
    }

    private static let keyNamesByCode: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "a", UInt32(kVK_ANSI_B): "b", UInt32(kVK_ANSI_C): "c",
        UInt32(kVK_ANSI_D): "d", UInt32(kVK_ANSI_E): "e", UInt32(kVK_ANSI_F): "f",
        UInt32(kVK_ANSI_G): "g", UInt32(kVK_ANSI_H): "h", UInt32(kVK_ANSI_I): "i",
        UInt32(kVK_ANSI_J): "j", UInt32(kVK_ANSI_K): "k", UInt32(kVK_ANSI_L): "l",
        UInt32(kVK_ANSI_M): "m", UInt32(kVK_ANSI_N): "n", UInt32(kVK_ANSI_O): "o",
        UInt32(kVK_ANSI_P): "p", UInt32(kVK_ANSI_Q): "q", UInt32(kVK_ANSI_R): "r",
        UInt32(kVK_ANSI_S): "s", UInt32(kVK_ANSI_T): "t", UInt32(kVK_ANSI_U): "u",
        UInt32(kVK_ANSI_V): "v", UInt32(kVK_ANSI_W): "w", UInt32(kVK_ANSI_X): "x",
        UInt32(kVK_ANSI_Y): "y", UInt32(kVK_ANSI_Z): "z",
        UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_F1): "F1", UInt32(kVK_F2): "F2", UInt32(kVK_F3): "F3",
        UInt32(kVK_F4): "F4", UInt32(kVK_F5): "F5", UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7", UInt32(kVK_F8): "F8", UInt32(kVK_F9): "F9",
        UInt32(kVK_F10): "F10", UInt32(kVK_F11): "F11", UInt32(kVK_F12): "F12",
        UInt32(kVK_LeftArrow): "←", UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑", UInt32(kVK_DownArrow): "↓",
        UInt32(kVK_Space): "Space", UInt32(kVK_Tab): "Tab",
        UInt32(kVK_ANSI_Minus): "-", UInt32(kVK_ANSI_Equal): "=",
        UInt32(kVK_ANSI_LeftBracket): "[", UInt32(kVK_ANSI_RightBracket): "]",
        UInt32(kVK_ANSI_Backslash): "\\", UInt32(kVK_ANSI_Semicolon): ";",
        UInt32(kVK_ANSI_Quote): "'", UInt32(kVK_ANSI_Comma): ",",
        UInt32(kVK_ANSI_Period): ".", UInt32(kVK_ANSI_Slash): "/",
        UInt32(kVK_ANSI_Grave): "`"
    ]

    private static let keyCodesByName = Dictionary(
        uniqueKeysWithValues: keyNamesByCode.map { ($0.value.lowercased(), $0.key) }
    )
}

enum ExpirationPolicy: Equatable, Sendable {
    case never
    case after(TimeInterval)
}

enum AppConfiguration {
    static let productName = "Pasteboard"
    static let bundleIdentifier = "com.sinaanahd.Pasteboard"
    static let authorName = "Sina Anahid"
    static let copyrightNotice = "Copyright © 2026 \(authorName)"
    static let developmentVersionFallback = "1.2.2"
    static var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? developmentVersionFallback
    }
    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "7"
    }
    static var applicationSupportURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(applicationSupportDirectoryName, isDirectory: true)
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
