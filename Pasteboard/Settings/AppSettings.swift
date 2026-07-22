import AppKit
import Combine
import Foundation

enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case features
    case shortcuts
    case privacyStorage
    case about

    var id: String { rawValue }
}

enum PanelPositionPreference: String, CaseIterable, Codable, Identifiable, Sendable {
    case nearPointer
    case activeScreenCenter
    case rememberLastPosition

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nearPointer: "Near pointer"
        case .activeScreenCenter: "Center of active screen"
        case .rememberLastPosition: "Remember last position"
        }
    }
}

enum ScreenshotCompletionBehavior: String, CaseIterable, Codable, Identifiable, Sendable {
    case historyAndClipboard
    case historyOnly
    case clipboardOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .historyAndClipboard: "Add to history and copy to clipboard"
        case .historyOnly: "Add to history only"
        case .clipboardOnly: "Copy to clipboard only"
        }
    }
}

enum ExpirationOption: String, CaseIterable, Codable, Identifiable, Sendable {
    case never
    case oneHour
    case oneDay
    case sevenDays
    case thirtyDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .never: "Never"
        case .oneHour: "After 1 hour"
        case .oneDay: "After 1 day"
        case .sevenDays: "After 7 days"
        case .thirtyDays: "After 30 days"
        }
    }

    var policy: ExpirationPolicy {
        switch self {
        case .never: .never
        case .oneHour: .after(60 * 60)
        case .oneDay: .after(24 * 60 * 60)
        case .sevenDays: .after(7 * 24 * 60 * 60)
        case .thirtyDays: .after(30 * 24 * 60 * 60)
        }
    }
}

struct PersistedPanelOrigin: Codable, Equatable, Sendable {
    let x: Double
    let y: Double

    init(_ point: NSPoint) {
        x = point.x
        y = point.y
    }

    var point: NSPoint { NSPoint(x: x, y: y) }
}

@MainActor
final class AppSettings: ObservableObject {
    static let selectedPaneDefaultsKey = "settings.selectedPane"

    enum Limits {
        static let history = 10...100_000
        static let image = 5...10_000
        static let historyWarning = 1_000
        static let imageWarning = 500
    }

    private enum Key {
        static let historyShortcut = "settings.historyShortcut"
        static let screenshotShortcut = "settings.screenshotShortcut"
        static let historyLimit = "settings.historyLimit"
        static let imageLimit = "settings.imageLimit"
        static let automaticPaste = "settings.automaticPaste"
        static let launchAtLogin = "settings.launchAtLogin"
        static let expiration = "settings.expiration"
        static let panelPosition = "settings.panelPosition"
        static let lastPanelOrigin = "settings.lastPanelOrigin"
        static let screenshotBehavior = "settings.screenshotBehavior"
        static let monitoring = "settings.monitoring"
        static let excludedApplications = "settings.excludedApplications"
    }

    private let defaults: UserDefaults

    @Published var historyShortcut: KeyboardShortcut { didSet { save(historyShortcut, forKey: Key.historyShortcut) } }
    @Published var screenshotShortcut: KeyboardShortcut { didSet { save(screenshotShortcut, forKey: Key.screenshotShortcut) } }
    @Published var historyLimit: Int {
        didSet {
            let normalized = Self.normalizedHistoryLimit(historyLimit)
            if historyLimit != normalized {
                historyLimit = normalized
                return
            }
            defaults.set(historyLimit, forKey: Key.historyLimit)
        }
    }
    @Published var imageLimit: Int {
        didSet {
            let normalized = Self.normalizedImageLimit(imageLimit)
            if imageLimit != normalized {
                imageLimit = normalized
                return
            }
            defaults.set(imageLimit, forKey: Key.imageLimit)
        }
    }
    @Published var automaticPasteEnabled: Bool { didSet { defaults.set(automaticPasteEnabled, forKey: Key.automaticPaste) } }
    @Published var launchAtLoginEnabled: Bool { didSet { defaults.set(launchAtLoginEnabled, forKey: Key.launchAtLogin) } }
    @Published var expiration: ExpirationOption { didSet { defaults.set(expiration.rawValue, forKey: Key.expiration) } }
    @Published var panelPosition: PanelPositionPreference { didSet { defaults.set(panelPosition.rawValue, forKey: Key.panelPosition) } }
    @Published var lastPanelOrigin: PersistedPanelOrigin? {
        didSet {
            if let lastPanelOrigin {
                save(lastPanelOrigin, forKey: Key.lastPanelOrigin)
            } else {
                defaults.removeObject(forKey: Key.lastPanelOrigin)
            }
        }
    }
    @Published var screenshotBehavior: ScreenshotCompletionBehavior { didSet { defaults.set(screenshotBehavior.rawValue, forKey: Key.screenshotBehavior) } }
    @Published var monitoringEnabled: Bool { didSet { defaults.set(monitoringEnabled, forKey: Key.monitoring) } }
    @Published var excludedBundleIdentifiers: Set<String> {
        didSet { defaults.set(excludedBundleIdentifiers.sorted(), forKey: Key.excludedApplications) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        historyShortcut = Self.readShortcut(
            from: defaults, key: Key.historyShortcut,
            fallback: AppConfiguration.defaultHistoryShortcut
        )
        screenshotShortcut = Self.readShortcut(
            from: defaults, key: Key.screenshotShortcut,
            fallback: AppConfiguration.defaultScreenshotShortcut
        )
        historyLimit = Self.normalizedHistoryLimit(
            defaults.object(forKey: Key.historyLimit) as? Int ?? AppConfiguration.defaultHistoryLimit
        )
        imageLimit = Self.normalizedImageLimit(
            defaults.object(forKey: Key.imageLimit) as? Int ?? AppConfiguration.defaultImageLimit
        )
        automaticPasteEnabled = defaults.object(forKey: Key.automaticPaste) as? Bool
            ?? AppConfiguration.defaultAutomaticPasteEnabled
        launchAtLoginEnabled = defaults.object(forKey: Key.launchAtLogin) as? Bool ?? false
        expiration = ExpirationOption(rawValue: defaults.string(forKey: Key.expiration) ?? "") ?? .never
        panelPosition = PanelPositionPreference(
            rawValue: defaults.string(forKey: Key.panelPosition) ?? ""
        ) ?? .nearPointer
        lastPanelOrigin = Self.read(PersistedPanelOrigin.self, from: defaults, key: Key.lastPanelOrigin)
        screenshotBehavior = ScreenshotCompletionBehavior(
            rawValue: defaults.string(forKey: Key.screenshotBehavior) ?? ""
        ) ?? .historyAndClipboard
        monitoringEnabled = defaults.object(forKey: Key.monitoring) as? Bool ?? true
        let identifiers = defaults.stringArray(forKey: Key.excludedApplications) ?? []
        excludedBundleIdentifiers = Set(identifiers.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
    }

    func resetHistoryShortcut() { historyShortcut = AppConfiguration.defaultHistoryShortcut }
    func resetScreenshotShortcut() { screenshotShortcut = AppConfiguration.defaultScreenshotShortcut }
    func resetHistoryLimit() { historyLimit = AppConfiguration.defaultHistoryLimit }
    func resetImageLimit() { imageLimit = AppConfiguration.defaultImageLimit }

    func resetAll() {
        historyShortcut = AppConfiguration.defaultHistoryShortcut
        screenshotShortcut = AppConfiguration.defaultScreenshotShortcut
        historyLimit = AppConfiguration.defaultHistoryLimit
        imageLimit = AppConfiguration.defaultImageLimit
        automaticPasteEnabled = AppConfiguration.defaultAutomaticPasteEnabled
        launchAtLoginEnabled = false
        expiration = .never
        panelPosition = .nearPointer
        lastPanelOrigin = nil
        screenshotBehavior = .historyAndClipboard
        monitoringEnabled = true
        excludedBundleIdentifiers = []
    }

    static func normalizedHistoryLimit(_ value: Int) -> Int {
        min(max(value, Limits.history.lowerBound), Limits.history.upperBound)
    }

    static func normalizedImageLimit(_ value: Int) -> Int {
        min(max(value, Limits.image.lowerBound), Limits.image.upperBound)
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }

    private static func read<T: Decodable>(_ type: T.Type, from defaults: UserDefaults, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func readShortcut(from defaults: UserDefaults,
                                     key: String,
                                     fallback: KeyboardShortcut) -> KeyboardShortcut {
        guard let shortcut = read(KeyboardShortcut.self, from: defaults, key: key),
              shortcut.isStructurallyValid else { return fallback }
        return shortcut
    }
}
