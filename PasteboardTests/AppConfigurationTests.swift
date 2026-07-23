import XCTest
@testable import Pasteboard

final class AppConfigurationTests: XCTestCase {
    func testProductDefaultsAreSafeAndBounded() {
        XCTAssertEqual(AppConfiguration.productName, "Pasteboard")
        XCTAssertEqual(AppConfiguration.bundleIdentifier, "com.sinaanahd.Pasteboard")
        XCTAssertEqual(AppConfiguration.authorName, "Sina Anahid")
        XCTAssertEqual(AppConfiguration.copyrightNotice, "Copyright © 2026 Sina Anahid")
        XCTAssertEqual(AppConfiguration.developmentVersionFallback, "1.2.2")
        XCTAssertEqual(AppConfiguration.developmentVersionFallback.split(separator: ".").count, 3)
        XCTAssertGreaterThan(AppConfiguration.defaultHistoryLimit, 0)
        XCTAssertGreaterThan(AppConfiguration.clipboardPollingInterval, 0)
    }

    func testShortcutDisplayName() {
        XCTAssertEqual(AppConfiguration.defaultHistoryShortcut.displayName, "⌥V")
        XCTAssertNotNil(AppConfiguration.defaultHistoryShortcut.carbonKeyCode)
        XCTAssertNotEqual(AppConfiguration.defaultHistoryShortcut.carbonModifiers, 0)
        XCTAssertEqual(AppConfiguration.defaultScreenshotShortcut.displayName, "⌥⇧4")
        XCTAssertNotNil(AppConfiguration.defaultScreenshotShortcut.carbonKeyCode)
    }
}
