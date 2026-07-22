import Foundation

enum ClipboardEntryKind: String, Codable, Sendable {
    case text
    case image
    case file
}

struct ClipboardEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let text: String?
    let imageFilename: String?
    let filePaths: [String]?
    let contentHash: String?
    let createdAt: Date

    init(id: UUID = UUID(), text: String, createdAt: Date = .now) {
        self.id = id
        self.text = text
        imageFilename = nil
        filePaths = nil
        contentHash = nil
        self.createdAt = createdAt
    }

    init(id: UUID = UUID(), imageFilename: String, contentHash: String, createdAt: Date = .now) {
        self.id = id
        text = nil
        self.imageFilename = imageFilename
        filePaths = nil
        self.contentHash = contentHash
        self.createdAt = createdAt
    }

    init(id: UUID = UUID(), fileURLs: [URL], contentHash: String, createdAt: Date = .now) {
        self.id = id
        text = nil
        imageFilename = nil
        filePaths = fileURLs.map(\.path)
        self.contentHash = contentHash
        self.createdAt = createdAt
    }

    var kind: ClipboardEntryKind {
        if imageFilename != nil { return .image }
        if filePaths != nil { return .file }
        return .text
    }

    var preview: String {
        if let filePaths {
            let names = filePaths.map { URL(fileURLWithPath: $0).lastPathComponent }
            return names.count == 1 ? names[0] : "\(names.count) files: " + names.joined(separator: ", ")
        }
        guard let text else { return "Image" }
        return text.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
