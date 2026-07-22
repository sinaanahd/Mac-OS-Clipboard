import Foundation

enum ClipboardEntryKind: String, Codable, Sendable {
    case text
    case image
}

struct ClipboardEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let text: String?
    let imageFilename: String?
    let contentHash: String?
    let createdAt: Date

    init(id: UUID = UUID(), text: String, createdAt: Date = .now) {
        self.id = id
        self.text = text
        imageFilename = nil
        contentHash = nil
        self.createdAt = createdAt
    }

    init(id: UUID = UUID(), imageFilename: String, contentHash: String, createdAt: Date = .now) {
        self.id = id
        text = nil
        self.imageFilename = imageFilename
        self.contentHash = contentHash
        self.createdAt = createdAt
    }

    var kind: ClipboardEntryKind { imageFilename == nil ? .text : .image }

    var preview: String {
        guard let text else { return "Image" }
        return text.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
