import Foundation

protocol ClipboardHistoryPersisting: Sendable {
    func load() throws -> [ClipboardEntry]
    func save(_ entries: [ClipboardEntry]) throws
    func flush()
}

extension ClipboardHistoryPersisting {
    func flush() {}
}

struct JSONClipboardHistoryPersistence: ClipboardHistoryPersisting {
    let fileURL: URL

    func load() throws -> [ClipboardEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        return try JSONDecoder().decode([ClipboardEntry].self, from: Data(contentsOf: fileURL))
    }

    func save(_ entries: [ClipboardEntry]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(entries).write(to: fileURL, options: .atomic)
    }

    static func live() -> CoalescingJSONClipboardHistoryPersistence {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return CoalescingJSONClipboardHistoryPersistence(fileURL: baseURL
            .appendingPathComponent(AppConfiguration.applicationSupportDirectoryName, isDirectory: true)
            .appendingPathComponent(AppConfiguration.interimTextHistoryFilename))
    }
}

final class CoalescingJSONClipboardHistoryPersistence: ClipboardHistoryPersisting, @unchecked Sendable {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.sinaanahd.Pasteboard.history-writer",
                                      qos: .utility)
    private let lock = NSLock()
    private var latestEntries: [ClipboardEntry]?
    private var writeScheduled = false
    private var lastError: (any Error)?

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func load() throws -> [ClipboardEntry] {
        flush()
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        return try JSONDecoder().decode([ClipboardEntry].self, from: Data(contentsOf: fileURL))
    }

    func save(_ entries: [ClipboardEntry]) throws {
        lock.lock()
        defer { lock.unlock() }
        if let lastError {
            self.lastError = nil
            throw lastError
        }
        latestEntries = entries
        guard !writeScheduled else { return }
        writeScheduled = true
        queue.asyncAfter(deadline: .now() + 0.15) { [weak self] in self?.writeLatest() }
    }

    func flush() {
        queue.sync { writeLatest() }
    }

    private func writeLatest() {
        lock.lock()
        let entries = latestEntries
        latestEntries = nil
        writeScheduled = false
        lock.unlock()
        guard let entries else { return }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try JSONEncoder().encode(entries).write(to: fileURL, options: .atomic)
        } catch {
            lock.lock()
            lastError = error
            lock.unlock()
        }
    }
}
