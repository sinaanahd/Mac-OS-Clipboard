import AppKit
import Foundation

@MainActor
final class PasteboardMonitor {
    private let pasteboard: NSPasteboard
    private let store: ClipboardHistoryStore
    private var timer: Timer?
    private var lastChangeCount: Int

    init(pasteboard: NSPasteboard = .general, store: ClipboardHistoryStore) {
        self.pasteboard = pasteboard
        self.store = store
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: AppConfiguration.clipboardPollingInterval,
                                     repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        guard let text = pasteboard.string(forType: .string) else { return }
        store.capture(text: text)
    }
}
