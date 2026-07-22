import Foundation
import XCTest
@testable import Pasteboard

private final class MemoryPersistence: ClipboardHistoryPersisting, @unchecked Sendable {
    var entries: [ClipboardEntry] = []
    func load() throws -> [ClipboardEntry] { entries }
    func save(_ entries: [ClipboardEntry]) throws { self.entries = entries }
}

private final class MemoryImageStore: ImagePayloadStoring, @unchecked Sendable {
    var values: [String: Data] = [:]
    func save(_ data: Data, filename: String) throws { values[filename] = data }
    func data(filename: String) throws -> Data { try XCTUnwrap(values[filename]) }
    func remove(filename: String) throws { values[filename] = nil }
    func url(filename: String) -> URL { URL(fileURLWithPath: "/tmp/\(filename)") }
}

@MainActor
final class ClipboardHistoryStoreTests: XCTestCase {
    func testCaptureSuppressesConsecutiveDuplicatesAndEnforcesLimit() {
        let persistence = MemoryPersistence()
        let store = ClipboardHistoryStore(limit: 2, persistence: persistence)
        XCTAssertTrue(store.capture(text: "one"))
        XCTAssertFalse(store.capture(text: "one"))
        XCTAssertTrue(store.capture(text: "two"))
        XCTAssertTrue(store.capture(text: "three"))
        XCTAssertEqual(store.entries.map(\.text), ["three", "two"])
        XCTAssertEqual(persistence.entries, store.entries)
    }

    func testEmptyTextIsIgnored() {
        let store = ClipboardHistoryStore(persistence: MemoryPersistence())
        XCTAssertFalse(store.capture(text: ""))
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testImagesAreDeduplicatedLimitedAndCleanedUp() {
        let images = MemoryImageStore()
        let store = ClipboardHistoryStore(limit: 10, imageLimit: 1,
                                          persistence: MemoryPersistence(), imageStore: images)
        let first = Data([1, 2, 3])
        let second = Data([4, 5, 6])
        XCTAssertTrue(store.capture(imagePNGData: first))
        XCTAssertFalse(store.capture(imagePNGData: first))
        XCTAssertTrue(store.capture(imagePNGData: second))
        XCTAssertEqual(store.entries.filter { $0.kind == .image }.count, 1)
        XCTAssertEqual(images.values.count, 1)
    }
}
