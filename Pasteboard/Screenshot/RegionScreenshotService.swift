import AppKit
import CoreGraphics
import Foundation

@MainActor
final class RegionScreenshotService {
    private let store: ClipboardHistoryStore
    private let settings: AppSettings
    private var activeProcess: Process?

    init(store: ClipboardHistoryStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
    }

    func captureRegion() {
        guard activeProcess == nil else { return }
        guard CGPreflightScreenCaptureAccess() else {
            explainAndRequestPermission()
            return
        }

        let filename = ScreenshotFilenameGenerator.filename()
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".png")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", temporaryURL.path]
        process.terminationHandler = { [weak self] process in
            Task { @MainActor in
                self?.finish(process: process, temporaryURL: temporaryURL, filename: filename)
            }
        }
        do {
            try process.run()
            activeProcess = process
        } catch {
            activeProcess = nil
        }
    }

    private func finish(process: Process, temporaryURL: URL, filename: String) {
        guard process.terminationStatus == 0 else {
            completeImport(data: nil, temporaryURL: temporaryURL, filename: filename)
            return
        }
        Task { [weak self] in
            let data = await ScreenshotFileLoader.loadStablePNG(
                from: temporaryURL,
                timeout: AppConfiguration.screenshotImportTimeout,
                pollInterval: AppConfiguration.screenshotImportPollInterval
            )
            self?.completeImport(data: data, temporaryURL: temporaryURL, filename: filename)
        }
    }

    private func completeImport(data: Data?, temporaryURL: URL, filename: String) {
        defer {
            try? FileManager.default.removeItem(at: temporaryURL)
            activeProcess = nil
        }
        guard let data else { return }
        switch settings.screenshotBehavior {
        case .historyAndClipboard:
            store.capture(imagePNGData: data, preferredFilename: filename)
            PasteboardImageWriter.writePNG(data)
        case .historyOnly:
            store.capture(imagePNGData: data, preferredFilename: filename)
        case .clipboardOnly:
            PasteboardImageWriter.writePNG(data)
        }
    }

    private func explainAndRequestPermission() {
        let alert = NSAlert()
        alert.messageText = "Allow region screenshots?"
        alert.informativeText = "Pasteboard needs Screen Recording access so macOS can capture only the region you select. Captures stay on this Mac and are never uploaded."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")
        if alert.runModal() == .alertFirstButtonReturn {
            CGRequestScreenCaptureAccess()
        }
    }
}
