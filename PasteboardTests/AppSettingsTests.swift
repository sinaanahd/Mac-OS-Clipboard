import Foundation
import XCTest
@testable import Pasteboard

@MainActor
final class AppSettingsTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suite = "PasteboardTests.AppSettings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    func testDefaultsPreserveVersionOneBehavior() {
        let settings = AppSettings(defaults: makeDefaults())

        XCTAssertEqual(settings.historyShortcut, AppConfiguration.defaultHistoryShortcut)
        XCTAssertEqual(settings.screenshotShortcut, AppConfiguration.defaultScreenshotShortcut)
        XCTAssertEqual(settings.historyLimit, 200)
        XCTAssertEqual(settings.imageLimit, 50)
        XCTAssertTrue(settings.automaticPasteEnabled)
        XCTAssertTrue(settings.monitoringEnabled)
        XCTAssertFalse(settings.launchAtLoginEnabled)
        XCTAssertEqual(settings.expiration, .never)
        XCTAssertEqual(settings.panelPosition, .nearPointer)
        XCTAssertEqual(settings.screenshotBehavior, .historyAndClipboard)
        XCTAssertTrue(settings.excludedBundleIdentifiers.isEmpty)
    }

    func testSettingsPersistAndReload() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.historyLimit = 500
        settings.imageLimit = 100
        settings.automaticPasteEnabled = false
        settings.monitoringEnabled = false
        settings.expiration = .sevenDays
        settings.panelPosition = .activeScreenCenter
        settings.screenshotBehavior = .historyOnly
        settings.excludedBundleIdentifiers = ["com.example.Editor"]

        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.historyLimit, 500)
        XCTAssertEqual(reloaded.imageLimit, 100)
        XCTAssertFalse(reloaded.automaticPasteEnabled)
        XCTAssertFalse(reloaded.monitoringEnabled)
        XCTAssertEqual(reloaded.expiration, .sevenDays)
        XCTAssertEqual(reloaded.panelPosition, .activeScreenCenter)
        XCTAssertEqual(reloaded.screenshotBehavior, .historyOnly)
        XCTAssertEqual(reloaded.excludedBundleIdentifiers, ["com.example.Editor"])
    }

    func testInvalidSavedValuesNormalizeSafely() {
        let defaults = makeDefaults()
        defaults.set(-100, forKey: "settings.historyLimit")
        defaults.set(Int.max, forKey: "settings.imageLimit")
        defaults.set("invalid", forKey: "settings.expiration")
        defaults.set(Data("invalid".utf8), forKey: "settings.historyShortcut")

        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.historyLimit, AppSettings.Limits.history.lowerBound)
        XCTAssertEqual(settings.imageLimit, AppSettings.Limits.image.upperBound)
        XCTAssertEqual(settings.expiration, .never)
        XCTAssertEqual(settings.historyShortcut, AppConfiguration.defaultHistoryShortcut)

        settings.historyLimit = -1
        settings.imageLimit = Int.max
        XCTAssertEqual(settings.historyLimit, AppSettings.Limits.history.lowerBound)
        XCTAssertEqual(settings.imageLimit, AppSettings.Limits.image.upperBound)
    }

    func testResetAllRestoresDefaults() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.historyLimit = 900
        settings.imageLimit = 300
        settings.monitoringEnabled = false
        settings.excludedBundleIdentifiers = ["com.example.App"]

        settings.resetAll()

        XCTAssertEqual(settings.historyLimit, 200)
        XCTAssertEqual(settings.imageLimit, 50)
        XCTAssertTrue(settings.monitoringEnabled)
        XCTAssertTrue(settings.excludedBundleIdentifiers.isEmpty)
    }
}
