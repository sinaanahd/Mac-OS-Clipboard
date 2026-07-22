import Foundation
import XCTest
@testable import Pasteboard

final class ScreenshotFilenameGeneratorTests: XCTestCase {
    func testFilenameIsPredictableUniqueAndPNG() {
        let date = Date(timeIntervalSince1970: 0)
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let filename = ScreenshotFilenameGenerator.filename(date: date, id: id)
        XCTAssertTrue(filename.hasPrefix("Pasteboard-"))
        XCTAssertTrue(filename.hasSuffix("-00000000-0000-0000-0000-000000000001.png"))
        XCTAssertFalse(filename.contains("/"))
    }
}
