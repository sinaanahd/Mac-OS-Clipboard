import XCTest
@testable import Pasteboard

final class AppConfigurationTests: XCTestCase {
    func testProductDefaultsAreSafeAndBounded() {
        XCTAssertEqual(AppConfiguration.productName, "Pasteboard")
        XCTAssertEqual(AppConfiguration.bundleIdentifier, "com.sinaanahd.Pasteboard")
        XCTAssertGreaterThan(AppConfiguration.defaultHistoryLimit, 0)
        XCTAssertGreaterThan(AppConfiguration.clipboardPollingInterval, 0)
    }

    func testShortcutDisplayName() {
        XCTAssertEqual(AppConfiguration.defaultHistoryShortcut.displayName, "⇧⌘V")
        XCTAssertNotNil(AppConfiguration.defaultHistoryShortcut.carbonKeyCode)
        XCTAssertNotEqual(AppConfiguration.defaultHistoryShortcut.carbonModifiers, 0)
    }
}
