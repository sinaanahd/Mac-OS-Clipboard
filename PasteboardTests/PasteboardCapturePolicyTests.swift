import XCTest
@testable import Pasteboard

final class PasteboardCapturePolicyTests: XCTestCase {
    func testPausedMonitoringRejectsCapture() {
        XCTAssertFalse(PasteboardCapturePolicy.permitsCapture(
            monitoringEnabled: false,
            frontmostBundleIdentifier: "com.example.Editor",
            excludedBundleIdentifiers: []
        ))
    }

    func testExcludedFrontmostApplicationRejectsCapture() {
        XCTAssertFalse(PasteboardCapturePolicy.permitsCapture(
            monitoringEnabled: true,
            frontmostBundleIdentifier: "com.example.Secret",
            excludedBundleIdentifiers: ["com.example.Secret"]
        ))
    }

    func testIncludedAndUnknownApplicationsPermitCapture() {
        let exclusions: Set<String> = ["com.example.Secret"]
        XCTAssertTrue(PasteboardCapturePolicy.permitsCapture(
            monitoringEnabled: true,
            frontmostBundleIdentifier: "com.example.Editor",
            excludedBundleIdentifiers: exclusions
        ))
        XCTAssertTrue(PasteboardCapturePolicy.permitsCapture(
            monitoringEnabled: true,
            frontmostBundleIdentifier: nil,
            excludedBundleIdentifiers: exclusions
        ))
    }
}
