import AppKit
import Foundation

@MainActor
final class PasteboardMonitor {
    private let pasteboard: NSPasteboard
    private let store: ClipboardHistoryStore
    private let settings: AppSettings
    private var timer: Timer?
    private var lastChangeCount: Int

    init(pasteboard: NSPasteboard = .general, store: ClipboardHistoryStore, settings: AppSettings) {
        self.pasteboard = pasteboard
        self.store = store
        self.settings = settings
        lastChangeCount = pasteboard.changeCount
        if let identifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           settings.excludedBundleIdentifiers.contains(identifier) { return }
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
        guard PasteboardPrivacyFilter.shouldCapture(types: pasteboard.types ?? []) else { return }
        let fileURLs = readFileURLs()
        if !fileURLs.isEmpty {
            store.capture(fileURLs: fileURLs)
        } else if let pngData = pasteboard.data(forType: .png) ?? convertedPNGData() {
            store.capture(imagePNGData: pngData)
        } else if let text = pasteboard.string(forType: .string) {
            store.capture(text: text)
        }
    }

    private func readFileURLs() -> [URL] {
        let objects = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) ?? []
        return objects.compactMap { ($0 as? NSURL)?.absoluteURL }
    }

    private func convertedPNGData() -> Data? {
        guard let tiffData = pasteboard.data(forType: .tiff),
              let representation = NSBitmapImageRep(data: tiffData) else { return nil }
        return representation.representation(using: .png, properties: [:])
    }
}
