import Carbon.HIToolbox
import XCTest
@testable import Pasteboard

final class GlobalHotKeyTests: XCTestCase {
    func testNonmatchingHandlerAllowsCarbonToContinueDispatching() {
        let status = GlobalHotKey.eventDisposition(
            readStatus: noErr,
            eventIdentifier: 1,
            registeredIdentifier: 2
        )
        XCTAssertEqual(status, OSStatus(eventNotHandledErr))
    }

    func testMatchingHandlerConsumesEvent() {
        let status = GlobalHotKey.eventDisposition(
            readStatus: noErr,
            eventIdentifier: 1,
            registeredIdentifier: 1
        )
        XCTAssertEqual(status, noErr)
    }
}
