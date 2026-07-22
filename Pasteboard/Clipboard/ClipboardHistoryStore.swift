import AppKit
import Foundation

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    @Published private(set) var entries: [ClipboardEntry]
    private(set) var limit: Int
    private(set) var imageLimit: Int
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

    func clearUnpinned() {
        let removed = entries.filter { !$0.isPinned }
        guard !removed.isEmpty else { return }
        removePayloads(for: removed)
        entries.removeAll { !$0.isPinned }
        persist()
    }

    func flushPersistence() {
        persistence.flush()
    }

    func removalCount(historyLimit: Int, imageLimit: Int) -> Int {
        Self.prunedEntries(entries, historyLimit: historyLimit, imageLimit: imageLimit).removed.count
    }

    @discardableResult
    func updateLimits(historyLimit: Int, imageLimit: Int) -> Int {
        let result = Self.prunedEntries(entries, historyLimit: historyLimit, imageLimit: imageLimit)
        limit = max(1, historyLimit)
        self.imageLimit = max(1, imageLimit)
        guard !result.removed.isEmpty else { return 0 }
        removePayloads(for: result.removed)
        entries = result.kept
        persist()
        return result.removed.count
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
        let result = Self.prunedEntries(entries, historyLimit: limit, imageLimit: imageLimit)
        entries = result.kept
        removePayloads(for: result.removed)
        persist()
    }

    private static func prunedEntries(_ source: [ClipboardEntry],
                                      historyLimit: Int,
                                      imageLimit: Int) -> (kept: [ClipboardEntry], removed: [ClipboardEntry]) {
        var kept = source
        var removed: [ClipboardEntry] = []
        let safeImageLimit = max(1, imageLimit)
        let imageIndexes = kept.indices.filter { kept[$0].kind == .image && !kept[$0].isPinned }
        if imageIndexes.count > safeImageLimit {
            for index in imageIndexes.dropFirst(safeImageLimit).reversed() {
                removed.append(kept.remove(at: index))
            }
        }
        let safeHistoryLimit = max(1, historyLimit)
        let unpinnedIndexes = kept.indices.filter { !kept[$0].isPinned }
        if unpinnedIndexes.count > safeHistoryLimit {
            for index in unpinnedIndexes.dropFirst(safeHistoryLimit).reversed() {
                removed.append(kept.remove(at: index))
            }
        }
        return (kept, removed)
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
