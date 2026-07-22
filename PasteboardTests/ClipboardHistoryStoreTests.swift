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
    func filenames() throws -> [String] { Array(values.keys) }
    func url(filename: String) -> URL { URL(fileURLWithPath: "/tmp/\(filename)") }
}

@MainActor
final class ClipboardHistoryStoreTests: XCTestCase {
    func testCaptureSuppressesConsecutiveDuplicatesAndEnforcesLimit() {
        let persistence = MemoryPersistence()
        let store = ClipboardHistoryStore(limit: 2, persistence: persistence, imageStore: MemoryImageStore())
        XCTAssertTrue(store.capture(text: "one"))
        XCTAssertFalse(store.capture(text: "one"))
        XCTAssertTrue(store.capture(text: "two"))
        XCTAssertTrue(store.capture(text: "three"))
        XCTAssertEqual(store.entries.map(\.text), ["three", "two"])
        XCTAssertEqual(persistence.entries, store.entries)
    }

    func testEmptyTextIsIgnored() {
        let store = ClipboardHistoryStore(persistence: MemoryPersistence(), imageStore: MemoryImageStore())
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

    func testFileSelectionsAreNormalizedAndDeduplicated() {
        let store = ClipboardHistoryStore(persistence: MemoryPersistence(), imageStore: MemoryImageStore())
        let URL = URL(fileURLWithPath: "/tmp/folder/../document.txt")
        XCTAssertTrue(store.capture(fileURLs: [URL]))
        XCTAssertFalse(store.capture(fileURLs: [URL.standardizedFileURL]))
        XCTAssertEqual(store.entries.first?.kind, .file)
        XCTAssertEqual(store.entries.first?.filePaths, ["/tmp/document.txt"])
    }

    func testExpirationRemovesOldEntriesAndOwnedImagePayloads() {
        let persistence = MemoryPersistence()
        let images = MemoryImageStore()
        let store = ClipboardHistoryStore(persistence: persistence, imageStore: images)
        let now = Date(timeIntervalSince1970: 10_000)
        XCTAssertTrue(store.capture(imagePNGData: Data([1]), preferredFilename: "old.png", at: now.addingTimeInterval(-101)))
        XCTAssertTrue(store.capture(text: "recent", at: now.addingTimeInterval(-99)))

        store.cleanup(expirationPolicy: .after(100), now: now)

        XCTAssertEqual(store.entries.map(\.text), ["recent"])
        XCTAssertNil(images.values["old.png"])
        XCTAssertEqual(persistence.entries, store.entries)
    }

    func testNeverExpirationKeepsEntries() {
        let store = ClipboardHistoryStore(persistence: MemoryPersistence(), imageStore: MemoryImageStore())
        XCTAssertTrue(store.capture(text: "keep", at: .distantPast))
        store.cleanup(expirationPolicy: .never, now: .now)
        XCTAssertEqual(store.entries.count, 1)
    }

    func testInitializationRemovesOnlyOrphanedOwnedImages() {
        let persistence = MemoryPersistence()
        persistence.entries = [ClipboardEntry(imageFilename: "kept.png", contentHash: "hash")]
        let images = MemoryImageStore()
        images.values = ["kept.png": Data([1]), "orphan.png": Data([2])]

        _ = ClipboardHistoryStore(persistence: persistence, imageStore: images)

        XCTAssertNotNil(images.values["kept.png"])
        XCTAssertNil(images.values["orphan.png"])
    }
}
