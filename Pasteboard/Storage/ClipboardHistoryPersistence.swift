import Foundation

protocol ClipboardHistoryPersisting: Sendable {
    func load() throws -> [ClipboardEntry]
    func save(_ entries: [ClipboardEntry]) throws
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

    static func live() -> Self {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return Self(fileURL: baseURL
            .appendingPathComponent(AppConfiguration.applicationSupportDirectoryName, isDirectory: true)
            .appendingPathComponent(AppConfiguration.interimTextHistoryFilename))
    }
}
