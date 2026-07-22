import XCTest
@testable import Pasteboard

final class ScreenshotCompletionPlanTests: XCTestCase {
    func testHistoryAndClipboardRoutesToBothDestinations() {
        let plan = ScreenshotCompletionPlan(behavior: .historyAndClipboard)
        XCTAssertTrue(plan.addsToHistory)
        XCTAssertTrue(plan.copiesToClipboard)
        XCTAssertEqual(plan.confirmationMessage, "Screenshot saved and copied")
    }

    func testHistoryOnlyRoutesOnlyToHistory() {
        let plan = ScreenshotCompletionPlan(behavior: .historyOnly)
        XCTAssertTrue(plan.addsToHistory)
        XCTAssertFalse(plan.copiesToClipboard)
        XCTAssertEqual(plan.confirmationMessage, "Screenshot added to history")
    }

    func testClipboardOnlyRoutesOnlyToClipboard() {
        let plan = ScreenshotCompletionPlan(behavior: .clipboardOnly)
        XCTAssertFalse(plan.addsToHistory)
        XCTAssertTrue(plan.copiesToClipboard)
        XCTAssertEqual(plan.confirmationMessage, "Screenshot copied")
    }
}
