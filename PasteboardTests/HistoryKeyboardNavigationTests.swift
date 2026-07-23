import XCTest
@testable import Pasteboard

final class HistoryKeyboardNavigationTests: XCTestCase {
    func testMovingWithoutSelectionChoosesDirectionalBoundary() {
        let ids = ["first", "second", "third"]

        XCTAssertEqual(
            HistoryKeyboardNavigation.movedSelection(
                current: nil, ids: ids, direction: .next
            ),
            "first"
        )
        XCTAssertEqual(
            HistoryKeyboardNavigation.movedSelection(
                current: nil, ids: ids, direction: .previous
            ),
            "third"
        )
    }

    func testMovingAdvancesAndClampsAtBoundaries() {
        let ids = ["first", "second", "third"]

        XCTAssertEqual(
            HistoryKeyboardNavigation.movedSelection(
                current: "first", ids: ids, direction: .next
            ),
            "second"
        )
        XCTAssertEqual(
            HistoryKeyboardNavigation.movedSelection(
                current: "third", ids: ids, direction: .next
            ),
            "third"
        )
        XCTAssertEqual(
            HistoryKeyboardNavigation.movedSelection(
                current: "second", ids: ids, direction: .previous
            ),
            "first"
        )
        XCTAssertEqual(
            HistoryKeyboardNavigation.movedSelection(
                current: "first", ids: ids, direction: .previous
            ),
            "first"
        )
    }

    func testEmptyOrStaleSelectionIsHandledSafely() {
        XCTAssertNil(
            HistoryKeyboardNavigation.movedSelection(
                current: "missing", ids: [], direction: .next
            )
        )
        XCTAssertEqual(
            HistoryKeyboardNavigation.movedSelection(
                current: "missing", ids: ["first", "second"], direction: .next
            ),
            "first"
        )
    }
}
