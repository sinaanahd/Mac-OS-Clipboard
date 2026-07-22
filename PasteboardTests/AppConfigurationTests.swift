import XCTest
@testable import Pasteboard

final class AppConfigurationTests: XCTestCase {
    func testProductDefaultsAreSafeAndBounded() {
        XCTAssertEqual(AppConfiguration.productName, "Pasteboard")
        XCTAssertEqual(AppConfiguration.bundleIdentifier, "com.sinaanahd.Pasteboard")
        XCTAssertEqual(AppConfiguration.developmentVersionFallback, "1.0.0")
        XCTAssertEqual(AppConfiguration.developmentVersionFallback.split(separator: ".").count, 3)
        XCTAssertGreaterThan(AppConfiguration.defaultHistoryLimit, 0)
        XCTAssertGreaterThan(AppConfiguration.clipboardPollingInterval, 0)
    }

    func testShortcutDisplayName() {
        XCTAssertEqual(AppConfiguration.defaultHistoryShortcut.displayName, "⇧⌘V")
        XCTAssertNotNil(AppConfiguration.defaultHistoryShortcut.carbonKeyCode)
        XCTAssertNotEqual(AppConfiguration.defaultHistoryShortcut.carbonModifiers, 0)
    }
}
