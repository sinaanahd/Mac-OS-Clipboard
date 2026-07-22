import Foundation
import XCTest
@testable import Pasteboard

final class StorageUsageServiceTests: XCTestCase {
    func testCalculatorSeparatesMetadataAndImagePayloadBytes() async throws {
        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PasteboardStorageTests-\(UUID().uuidString)", isDirectory: true)
        let imagesURL = baseURL.appendingPathComponent(
            AppConfiguration.imagePayloadDirectoryName, isDirectory: true
        )
        try FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: baseURL) }
        try Data(repeating: 1, count: 12).write(
            to: baseURL.appendingPathComponent(AppConfiguration.interimTextHistoryFilename)
        )
        try Data(repeating: 2, count: 30).write(to: imagesURL.appendingPathComponent("one.png"))
        try Data(repeating: 3, count: 20).write(to: imagesURL.appendingPathComponent("two.png"))

        let usage = await StorageUsageCalculator().calculate(baseURL: baseURL)

        XCTAssertEqual(usage.metadataBytes, 12)
        XCTAssertEqual(usage.imageBytes, 50)
        XCTAssertEqual(usage.totalBytes, 62)
    }
}
