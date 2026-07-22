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
    var isPinned: Bool

    init(id: UUID = UUID(), text: String, createdAt: Date = .now, isPinned: Bool = false) {
        self.id = id
        self.text = text
        imageFilename = nil
        filePaths = nil
        contentHash = nil
        self.createdAt = createdAt
        self.isPinned = isPinned
    }

    init(id: UUID = UUID(), imageFilename: String, contentHash: String,
         createdAt: Date = .now, isPinned: Bool = false) {
        self.id = id
        text = nil
        self.imageFilename = imageFilename
        filePaths = nil
        self.contentHash = contentHash
        self.createdAt = createdAt
        self.isPinned = isPinned
    }

    init(id: UUID = UUID(), fileURLs: [URL], contentHash: String,
         createdAt: Date = .now, isPinned: Bool = false) {
        self.id = id
        text = nil
        imageFilename = nil
        filePaths = fileURLs.map(\.path)
        self.contentHash = contentHash
        self.createdAt = createdAt
        self.isPinned = isPinned
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, imageFilename, filePaths, contentHash, createdAt, isPinned
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        imageFilename = try container.decodeIfPresent(String.self, forKey: .imageFilename)
        filePaths = try container.decodeIfPresent([String].self, forKey: .filePaths)
        contentHash = try container.decodeIfPresent(String.self, forKey: .contentHash)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
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
