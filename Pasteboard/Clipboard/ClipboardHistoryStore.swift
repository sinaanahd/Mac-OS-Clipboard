import AppKit
import Foundation

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    @Published private(set) var entries: [ClipboardEntry]
    private let limit: Int
    private let persistence: any ClipboardHistoryPersisting

    init(limit: Int = AppConfiguration.defaultHistoryLimit,
         persistence: any ClipboardHistoryPersisting = JSONClipboardHistoryPersistence.live()) {
        self.limit = max(1, limit)
        self.persistence = persistence
        entries = (try? persistence.load()).map { Array($0.prefix(max(1, limit))) } ?? []
    }

    @discardableResult
    func capture(text: String, at date: Date = .now) -> Bool {
        guard !text.isEmpty, entries.first?.text != text else { return false }
        entries.insert(ClipboardEntry(text: text, createdAt: date), at: 0)
        entries = Array(entries.prefix(limit))
        persist()
        return true
    }

    func restore(_ entry: ClipboardEntry, to pasteboard: NSPasteboard = .general) {
        pasteboard.clearContents()
        pasteboard.setString(entry.text, forType: .string)
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        persist()
    }

    func clear() {
        entries.removeAll()
        persist()
    }

    private func persist() {
        try? persistence.save(entries)
    }
}
