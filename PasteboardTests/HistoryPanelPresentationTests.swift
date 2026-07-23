import Foundation
import XCTest
@testable import Pasteboard

@MainActor
final class HistoryPanelPresentationTests: XCTestCase {
    func testRefreshUsesProvidedReferenceDate() {
        let initialDate = Date(timeIntervalSince1970: 100)
        let refreshedDate = Date(timeIntervalSince1970: 200)
        let presentation = HistoryPanelPresentation(referenceDate: initialDate)

        presentation.refresh(at: refreshedDate)

        XCTAssertEqual(presentation.referenceDate, refreshedDate)
    }

    func testKeyboardStateTracksFocusSelectionAndResetsBetweenPresentations() {
        let presentation = HistoryPanelPresentation()
        let selection = UUID()

        presentation.keyboardSelection = selection
        presentation.setListFocused(true)

        XCTAssertEqual(presentation.keyboardSelection, selection)
        XCTAssertTrue(presentation.isListFocused)

        presentation.resetKeyboardState()

        XCTAssertNil(presentation.keyboardSelection)
        XCTAssertFalse(presentation.isListFocused)
    }

    func testRelativeTimeUsesSnapshotRatherThanCurrentClock() {
        let entryDate = Date(timeIntervalSince1970: 0)
        let referenceDate = Date(timeIntervalSince1970: 3_600)

        let first = HistoryRelativeTimeFormatter.string(from: entryDate, relativeTo: referenceDate)
        let second = HistoryRelativeTimeFormatter.string(from: entryDate, relativeTo: referenceDate)

        XCTAssertEqual(first, second)
        XCTAssertFalse(first.isEmpty)
    }
}
