import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var historyStore: ClipboardHistoryStore?
    private var monitor: PasteboardMonitor?
    private var panelController: HistoryPanelController?
    private var historyHotKey: GlobalHotKey?
    private var screenshotHotKey: GlobalHotKey?
    private var screenshotService: RegionScreenshotService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = ClipboardHistoryStore()
        let monitor = PasteboardMonitor(store: store)
        let panelController = HistoryPanelController(store: store)

        self.monitor = monitor
        historyStore = store
        self.panelController = panelController
        let screenshotService = RegionScreenshotService(store: store)
        self.screenshotService = screenshotService
        monitor.start()

        historyHotKey = try? GlobalHotKey(shortcut: AppConfiguration.defaultHistoryShortcut) {
            panelController.toggle()
        }
        screenshotHotKey = try? GlobalHotKey(
            shortcut: AppConfiguration.defaultScreenshotShortcut,
            identifier: 2
        ) {
            screenshotService.captureRegion()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stop()
    }

    func showHistory() {
        panelController?.show()
    }

    func captureRegion() {
        screenshotService?.captureRegion()
    }

    func confirmClearHistory() {
        guard let historyStore, !historyStore.entries.isEmpty else { return }
        let alert = NSAlert()
        alert.messageText = "Clear Clipboard History?"
        alert.informativeText = "This removes saved clipboard entries and Pasteboard-owned image copies. Original files referenced by the history will not be deleted."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear History")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        historyStore.clear()
    }
}
