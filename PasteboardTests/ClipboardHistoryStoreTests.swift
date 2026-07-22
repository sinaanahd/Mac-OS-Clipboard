import Foundation
import XCTest
@testable import Pasteboard

private final class MemoryPersistence: ClipboardHistoryPersisting, @unchecked Sendable {
    var entries: [ClipboardEntry] = []
    func load() throws -> [ClipboardEntry] { entries }
    func save(_ entries: [ClipboardEntry]) throws { self.entries = entries }
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
}
