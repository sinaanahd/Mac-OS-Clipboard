import AppKit
import XCTest
@testable import Pasteboard

final class PasteboardImageWriterTests: XCTestCase {
    func testWritesPNGForImmediatePaste() {
        let pasteboard = NSPasteboard(name: .init(UUID().uuidString))
        let data = Data([137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3])

        XCTAssertTrue(PasteboardImageWriter.writePNG(data, to: pasteboard))
        XCTAssertEqual(pasteboard.data(forType: .png), data)
    }

    func testEmptyDataDoesNotReplaceExistingPasteboardContents() {
        let pasteboard = NSPasteboard(name: .init(UUID().uuidString))
        pasteboard.setString("existing", forType: .string)

        XCTAssertFalse(PasteboardImageWriter.writePNG(Data(), to: pasteboard))
        XCTAssertEqual(pasteboard.string(forType: .string), "existing")
    }
}
