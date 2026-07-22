import Foundation
import XCTest
@testable import Pasteboard

final class ScreenshotFileLoaderTests: XCTestCase {
    func testLoadsPNGAfterFileSizeIsStable() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".png")
        defer { try? FileManager.default.removeItem(at: url) }
        let pngData = Data([137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3])
        try pngData.write(to: url, options: .atomic)

        let loaded = await ScreenshotFileLoader.loadStablePNG(
            from: url,
            timeout: .seconds(1),
            pollInterval: .milliseconds(10)
        )

        XCTAssertEqual(loaded, pngData)
    }

    func testRejectsNonPNGData() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".png")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("not a png".utf8).write(to: url, options: .atomic)

        let loaded = await ScreenshotFileLoader.loadStablePNG(
            from: url,
            timeout: .milliseconds(20),
            pollInterval: .milliseconds(5)
        )

        XCTAssertNil(loaded)
    }
}
