import AppKit
import Carbon.HIToolbox
import XCTest
@testable import Pasteboard

@MainActor
final class ShortcutCoordinatorTests: XCTestCase {
    private final class Token {}

    private func makeSettings() -> AppSettings {
        let suite = "PasteboardTests.Shortcuts.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return AppSettings(defaults: defaults)
    }

    func testSerializationUsesStableKeyCodeAndModifiers() throws {
        let shortcut = KeyboardShortcut(keyCode: UInt32(kVK_ANSI_K), modifiers: [.command, .shift])!
        let decoded = try JSONDecoder().decode(KeyboardShortcut.self,
                                               from: JSONEncoder().encode(shortcut))
        XCTAssertEqual(decoded, shortcut)
        XCTAssertEqual(decoded.displayName, "⇧⌘K")
    }

    func testRejectsBareAndUnsupportedKeys() {
        XCTAssertFalse(KeyboardShortcut(key: "v", modifiers: []).isStructurallyValid)
        XCTAssertNil(KeyboardShortcut(keyCode: UInt32(kVK_Return), modifiers: [.option]))
    }

    func testInvalidSerializedModifierDataIsRejected() throws {
        let json = Data("{\"keyCode\":9,\"modifierRawValue\":1}".utf8)
        let decoded = try JSONDecoder().decode(KeyboardShortcut.self, from: json)
        XCTAssertFalse(decoded.isStructurallyValid)
    }

    func testDistinctIdentifiersAndSuccessfulRuntimeReplacement() throws {
        let settings = makeSettings()
        var identifiers: [UInt32] = []
        let coordinator = ShortcutCoordinator { _, identifier, _ in
            identifiers.append(identifier)
            return Token()
        }
        coordinator.start(settings: settings, historyAction: {}, screenshotAction: {})
        let replacement = KeyboardShortcut(key: "k", modifiers: [.command, .option])

        try coordinator.update(.history, to: replacement).get()
        XCTAssertEqual(settings.historyShortcut, replacement)
        XCTAssertEqual(Set(identifiers.prefix(2)), Set([ShortcutKind.history.identifier,
                                                        ShortcutKind.screenshot.identifier]))
    }

    func testDuplicateIsRejectedAndOldShortcutRemains() {
        let settings = makeSettings()
        let coordinator = ShortcutCoordinator { _, _, _ in Token() }
        coordinator.start(settings: settings, historyAction: {}, screenshotAction: {})

        let result = coordinator.update(.history, to: settings.screenshotShortcut)
        assertFailure(result, equals: .duplicate)
        XCTAssertEqual(settings.historyShortcut, AppConfiguration.defaultHistoryShortcut)
        XCTAssertTrue(coordinator.activeKinds.contains(.history))
    }

    func testFailedRegistrationPreservesActiveAndPersistedShortcut() {
        let settings = makeSettings()
        var shouldFail = false
        let coordinator = ShortcutCoordinator { _, _, _ in
            if shouldFail {
                throw GlobalHotKeyError.registrationFailed(OSStatus(eventHotKeyExistsErr))
            }
            return Token()
        }
        coordinator.start(settings: settings, historyAction: {}, screenshotAction: {})
        shouldFail = true

        let result = coordinator.update(.history,
                                        to: KeyboardShortcut(key: "k", modifiers: [.option]))
        assertFailure(result, equals: .unavailable)
        XCTAssertEqual(settings.historyShortcut, AppConfiguration.defaultHistoryShortcut)
        XCTAssertTrue(coordinator.activeKinds.contains(.history))
    }

    func testRemoveAndResetShortcut() throws {
        let settings = makeSettings()
        let coordinator = ShortcutCoordinator { _, _, _ in Token() }
        coordinator.start(settings: settings, historyAction: {}, screenshotAction: {})

        try coordinator.update(.history, to: nil).get()
        XCTAssertFalse(settings.historyShortcutEnabled)
        XCTAssertFalse(coordinator.activeKinds.contains(.history))
        try coordinator.update(.history, to: AppConfiguration.defaultHistoryShortcut).get()
        XCTAssertTrue(settings.historyShortcutEnabled)
        XCTAssertTrue(coordinator.activeKinds.contains(.history))
    }

    private func assertFailure(_ result: Result<Void, ShortcutUpdateError>,
                               equals expected: ShortcutUpdateError,
                               file: StaticString = #filePath,
                               line: UInt = #line) {
        guard case let .failure(error) = result else {
            return XCTFail("Expected failure \(expected)", file: file, line: line)
        }
        XCTAssertEqual(error, expected, file: file, line: line)
    }
}
