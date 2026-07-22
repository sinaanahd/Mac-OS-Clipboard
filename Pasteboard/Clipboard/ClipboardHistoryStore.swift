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
        do {
            entries = try persistence.load()
            sortEntries()
            pruneAndPersist()
            cleanup(expirationPolicy: AppConfiguration.defaultExpirationPolicy)
            removeOrphanedImagePayloads()
        } catch {
            entries = []
        }
    }

    @discardableResult
    func capture(text: String, at date: Date = .now) -> Bool {
        guard !text.isEmpty, mostRecentEntry?.text != text else { return false }
        entries.insert(ClipboardEntry(text: text, createdAt: date), at: 0)
        pruneAndPersist()
        return true
    }

    @discardableResult
    func capture(imagePNGData: Data, preferredFilename: String? = nil, at date: Date = .now) -> Bool {
        guard !imagePNGData.isEmpty else { return false }
        let hash = ImageContentHash.make(for: imagePNGData)
        guard mostRecentEntry?.contentHash != hash else { return false }
        let id = UUID()
        let filename = preferredFilename ?? (id.uuidString + ".png")
        guard (try? imageStore.save(imagePNGData, filename: filename)) != nil else { return false }
        entries.insert(ClipboardEntry(id: id, imageFilename: filename, contentHash: hash, createdAt: date), at: 0)
        pruneAndPersist()
        return true
    }

    @discardableResult
    func capture(fileURLs: [URL], at date: Date = .now) -> Bool {
        let normalized = fileURLs.filter(\.isFileURL).map { $0.standardizedFileURL }
        guard !normalized.isEmpty else { return false }
        let hash = ImageContentHash.make(for: Data(normalized.map(\.path).joined(separator: "\u{0}").utf8))
        guard mostRecentEntry?.contentHash != hash else { return false }
        entries.insert(ClipboardEntry(fileURLs: normalized, contentHash: hash, createdAt: date), at: 0)
        pruneAndPersist()
        return true
    }

    func restore(_ entry: ClipboardEntry, to pasteboard: NSPasteboard = .general) {
        pasteboard.clearContents()
        if let text = entry.text {
            pasteboard.setString(text, forType: .string)
        } else if let paths = entry.filePaths {
            let URLs = paths.map { NSURL(fileURLWithPath: $0) }
            pasteboard.writeObjects(URLs)
        } else if let filename = entry.imageFilename,
                  let data = try? imageStore.data(filename: filename) {
            pasteboard.setData(data, forType: .png)
        }
    }

    func fileURL(for entry: ClipboardEntry) -> URL? {
        entry.filePaths?.first.map { URL(fileURLWithPath: $0) }
    }

    func imageURL(for entry: ClipboardEntry) -> URL? {
        guard let filename = entry.imageFilename else { return nil }
        return imageStore.url(filename: filename)
    }

    func togglePin(id: ClipboardEntry.ID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].isPinned.toggle()
        sortEntries()
        persist()
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
        removeOrphanedImagePayloads()
    }

    func cleanup(expirationPolicy: ExpirationPolicy, now: Date = .now) {
        guard case let .after(interval) = expirationPolicy, interval > 0 else { return }
        let cutoff = now.addingTimeInterval(-interval)
        let expired = entries.filter { !$0.isPinned && $0.createdAt < cutoff }
        guard !expired.isEmpty else { return }
        removePayloads(for: expired)
        entries.removeAll { !$0.isPinned && $0.createdAt < cutoff }
        persist()
    }

    private func pruneAndPersist() {
        sortEntries()
        var removed: [ClipboardEntry] = []
        let imageIndexes = entries.indices.filter {
            entries[$0].kind == .image && !entries[$0].isPinned
        }
        if imageIndexes.count > imageLimit {
            for index in imageIndexes.dropFirst(imageLimit).reversed() {
                removed.append(entries.remove(at: index))
            }
        }
        let unpinnedIndexes = entries.indices.filter { !entries[$0].isPinned }
        if unpinnedIndexes.count > limit {
            for index in unpinnedIndexes.dropFirst(limit).reversed() {
                removed.append(entries.remove(at: index))
            }
        }
        removePayloads(for: removed)
        persist()
    }

    private func removePayloads(for entries: [ClipboardEntry]) {
        for filename in entries.compactMap(\.imageFilename) {
            try? imageStore.remove(filename: filename)
        }
    }

    private var mostRecentEntry: ClipboardEntry? {
        entries.max { $0.createdAt < $1.createdAt }
    }

    private func sortEntries() {
        entries.sort {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.createdAt > $1.createdAt
        }
    }

    private func removeOrphanedImagePayloads() {
        let referencedFilenames = Set(entries.compactMap(\.imageFilename))
        guard let storedFilenames = try? imageStore.filenames() else { return }
        for filename in storedFilenames where !referencedFilenames.contains(filename) {
            try? imageStore.remove(filename: filename)
        }
    }

    private func persist() { try? persistence.save(entries) }
}
