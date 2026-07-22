import AppKit
import XCTest
@testable import Pasteboard

final class PanelPlacementTests: XCTestCase {
    private let frame = NSRect(x: 100, y: 50, width: 1_200, height: 800)
    private let size = NSSize(width: 420, height: 580)

    func testCentersOnActiveScreen() {
        let origin = PanelPlacement.origin(preference: .activeScreenCenter,
                                           pointer: .zero, panelSize: size,
                                           visibleFrame: frame, rememberedOrigin: nil)
        XCTAssertEqual(origin, NSPoint(x: 490, y: 160))
    }

    func testNearPointerIsConstrainedToVisibleFrame() {
        let origin = PanelPlacement.origin(preference: .nearPointer,
                                           pointer: NSPoint(x: 1_290, y: 60),
                                           panelSize: size, visibleFrame: frame,
                                           rememberedOrigin: nil)
        XCTAssertEqual(origin, NSPoint(x: 880, y: 50))
    }

    func testRememberedOriginIsConstrainedToVisibleFrame() {
        let origin = PanelPlacement.origin(preference: .rememberLastPosition,
                                           pointer: .zero, panelSize: size,
                                           visibleFrame: frame,
                                           rememberedOrigin: NSPoint(x: -500, y: 2_000))
        XCTAssertEqual(origin, NSPoint(x: 100, y: 270))
    }
}
