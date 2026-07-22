import AppKit
import Combine
import Foundation

enum ShortcutKind: CaseIterable, Hashable, Sendable {
    case history
    case screenshot

    var identifier: UInt32 { self == .history ? 1 : 2 }
}

enum ShortcutUpdateError: Error, Equatable {
    case invalid
    case duplicate
    case unavailable

    var message: String {
        switch self {
        case .invalid:
            "Use a supported key with Command, Option, Control, or Shift."
        case .duplicate:
            "History and screenshot shortcuts must be different."
        case .unavailable:
            "This shortcut is already used by macOS or another application. Choose a different combination."
        }
    }
}

@MainActor
final class ShortcutCoordinator: ObservableObject {
    typealias Action = @MainActor @Sendable () -> Void
    typealias Factory = (KeyboardShortcut, UInt32, @escaping Action) throws -> AnyObject

    @Published private(set) var errors: [ShortcutKind: ShortcutUpdateError] = [:]
    @Published private(set) var activeKinds: Set<ShortcutKind> = []

    private let factory: Factory
    private var registrations: [ShortcutKind: AnyObject] = [:]
    private var actions: [ShortcutKind: Action] = [:]
    private weak var settings: AppSettings?

    init(factory: @escaping Factory = { shortcut, identifier, action in
        try GlobalHotKey(shortcut: shortcut, identifier: identifier, action: action)
    }) {
        self.factory = factory
    }

    func start(settings: AppSettings,
               historyAction: @escaping Action,
               screenshotAction: @escaping Action) {
        self.settings = settings
        actions = [.history: historyAction, .screenshot: screenshotAction]
        registerInitial(.history, shortcut: settings.historyShortcut,
                        enabled: settings.historyShortcutEnabled)
        registerInitial(.screenshot, shortcut: settings.screenshotShortcut,
                        enabled: settings.screenshotShortcutEnabled)
    }

    @discardableResult
    func update(_ kind: ShortcutKind, to candidate: KeyboardShortcut?) -> Result<Void, ShortcutUpdateError> {
        guard let settings else { return .failure(.unavailable) }
        guard let candidate else {
            registrations[kind] = nil
            activeKinds.remove(kind)
            errors[kind] = nil
            setEnabled(false, for: kind, settings: settings)
            return .success(())
        }
        guard candidate.isStructurallyValid else { return fail(.invalid, for: kind) }

        let other: ShortcutKind = kind == .history ? .screenshot : .history
        if isEnabled(other, settings: settings), shortcut(for: other, settings: settings) == candidate {
            return fail(.duplicate, for: kind)
        }
        if isEnabled(kind, settings: settings), shortcut(for: kind, settings: settings) == candidate,
           activeKinds.contains(kind) {
            errors[kind] = nil
            return .success(())
        }
        guard let action = actions[kind] else { return fail(.unavailable, for: kind) }

        do {
            let replacement = try factory(candidate, kind.identifier, action)
            registrations[kind] = replacement
            activeKinds.insert(kind)
            errors[kind] = nil
            set(candidate, for: kind, settings: settings)
            setEnabled(true, for: kind, settings: settings)
            return .success(())
        } catch {
            return fail(.unavailable, for: kind)
        }
    }

    func reportInvalid(_ kind: ShortcutKind) {
        errors[kind] = .invalid
    }

    private func registerInitial(_ kind: ShortcutKind, shortcut: KeyboardShortcut, enabled: Bool) {
        guard enabled, let action = actions[kind] else { return }
        do {
            registrations[kind] = try factory(shortcut, kind.identifier, action)
            activeKinds.insert(kind)
            errors[kind] = nil
        } catch {
            registrations[kind] = nil
            activeKinds.remove(kind)
            errors[kind] = .unavailable
        }
    }

    private func fail(_ error: ShortcutUpdateError,
                      for kind: ShortcutKind) -> Result<Void, ShortcutUpdateError> {
        errors[kind] = error
        return .failure(error)
    }

    private func shortcut(for kind: ShortcutKind, settings: AppSettings) -> KeyboardShortcut {
        kind == .history ? settings.historyShortcut : settings.screenshotShortcut
    }

    private func isEnabled(_ kind: ShortcutKind, settings: AppSettings) -> Bool {
        kind == .history ? settings.historyShortcutEnabled : settings.screenshotShortcutEnabled
    }

    private func set(_ shortcut: KeyboardShortcut, for kind: ShortcutKind, settings: AppSettings) {
        if kind == .history { settings.historyShortcut = shortcut }
        else { settings.screenshotShortcut = shortcut }
    }

    private func setEnabled(_ enabled: Bool, for kind: ShortcutKind, settings: AppSettings) {
        if kind == .history { settings.historyShortcutEnabled = enabled }
        else { settings.screenshotShortcutEnabled = enabled }
    }
}
