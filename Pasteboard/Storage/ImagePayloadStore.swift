import CryptoKit
import Foundation

protocol ImagePayloadStoring: Sendable {
    func save(_ data: Data, filename: String) throws
    func data(filename: String) throws -> Data
    func remove(filename: String) throws
    func url(filename: String) -> URL
}

struct ImagePayloadStore: ImagePayloadStoring {
    let directoryURL: URL

    func save(_ data: Data, filename: String) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try data.write(to: url(filename: filename), options: .atomic)
    }

    func data(filename: String) throws -> Data {
        try Data(contentsOf: url(filename: filename))
    }

    func remove(filename: String) throws {
        let fileURL = url(filename: filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }

    func url(filename: String) -> URL { directoryURL.appendingPathComponent(filename) }

    static func live() -> Self {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return Self(directoryURL: baseURL
            .appendingPathComponent(AppConfiguration.applicationSupportDirectoryName, isDirectory: true)
            .appendingPathComponent(AppConfiguration.imagePayloadDirectoryName, isDirectory: true))
    }
}

enum ImageContentHash {
    static func make(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
