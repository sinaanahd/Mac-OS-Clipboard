import AppKit
import Foundation

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    @Published private(set) var entries: [ClipboardEntry]
    private let limit: Int
    private let imageLimit: Int
    private let persistence: any ClipboardHistoryPersisting
    private let imageStore: any ImagePayloadStoring

    init(limit: Int = AppConfiguration.defaultHistoryLimit,
         imageLimit: Int = AppConfiguration.defaultImageLimit,
         persistence: any ClipboardHistoryPersisting = JSONClipboardHistoryPersistence.live(),
         imageStore: any ImagePayloadStoring = ImagePayloadStore.live()) {
        self.limit = max(1, limit)
        self.imageLimit = max(1, imageLimit)
        self.persistence = persistence
        self.imageStore = imageStore
        entries = (try? persistence.load()).map { Array($0.prefix(max(1, limit))) } ?? []
    }

    @discardableResult
    func capture(text: String, at date: Date = .now) -> Bool {
        guard !text.isEmpty, entries.first?.text != text else { return false }
        entries.insert(ClipboardEntry(text: text, createdAt: date), at: 0)
        pruneAndPersist()
        return true
    }

    @discardableResult
    func capture(imagePNGData: Data, at date: Date = .now) -> Bool {
        guard !imagePNGData.isEmpty else { return false }
        let hash = ImageContentHash.make(for: imagePNGData)
        guard entries.first?.contentHash != hash else { return false }
        let id = UUID()
        let filename = id.uuidString + ".png"
        guard (try? imageStore.save(imagePNGData, filename: filename)) != nil else { return false }
        entries.insert(ClipboardEntry(id: id, imageFilename: filename, contentHash: hash, createdAt: date), at: 0)
        pruneAndPersist()
        return true
    }

    func restore(_ entry: ClipboardEntry, to pasteboard: NSPasteboard = .general) {
        pasteboard.clearContents()
        if let text = entry.text {
            pasteboard.setString(text, forType: .string)
        } else if let filename = entry.imageFilename,
                  let data = try? imageStore.data(filename: filename) {
            pasteboard.setData(data, forType: .png)
        }
    }

    func imageURL(for entry: ClipboardEntry) -> URL? {
        guard let filename = entry.imageFilename else { return nil }
        return imageStore.url(filename: filename)
    }

    func delete(at offsets: IndexSet) {
        removePayloads(for: offsets.map { entries[$0] })
        entries.remove(atOffsets: offsets)
        persist()
    }

    func clear() {
        removePayloads(for: entries)
        entries.removeAll()
        persist()
    }

    private func pruneAndPersist() {
        var removed: [ClipboardEntry] = []
        let imageIndexes = entries.indices.filter { entries[$0].kind == .image }
        if imageIndexes.count > imageLimit {
            for index in imageIndexes.dropFirst(imageLimit).reversed() {
                removed.append(entries.remove(at: index))
            }
        }
        if entries.count > limit {
            removed.append(contentsOf: entries.suffix(from: limit))
            entries = Array(entries.prefix(limit))
        }
        removePayloads(for: removed)
        persist()
    }

    private func removePayloads(for entries: [ClipboardEntry]) {
        for filename in entries.compactMap(\.imageFilename) {
            try? imageStore.remove(filename: filename)
        }
    }

    private func persist() { try? persistence.save(entries) }
}
