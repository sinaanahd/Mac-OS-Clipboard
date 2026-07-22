import Foundation
import XCTest
@testable import Pasteboard

final class ClipboardHistoryPersistenceTests: XCTestCase {
    func testCoalescedPersistenceFlushesLatestSnapshotAtomically() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PasteboardPersistenceTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("history.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = CoalescingJSONClipboardHistoryPersistence(fileURL: fileURL)

        try persistence.save([ClipboardEntry(text: "first")])
        try persistence.save([ClipboardEntry(text: "second")])
        try persistence.save([ClipboardEntry(text: "latest")])
        persistence.flush()

        let loaded = try JSONClipboardHistoryPersistence(fileURL: fileURL).load()
        XCTAssertEqual(loaded.map(\.text), ["latest"])
    }
}
