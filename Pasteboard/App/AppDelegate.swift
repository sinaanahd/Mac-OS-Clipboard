import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    let shortcutCoordinator = ShortcutCoordinator()
    private var historyStore: ClipboardHistoryStore?
    private var monitor: PasteboardMonitor?
    private var panelController: HistoryPanelController?
    private var screenshotService: RegionScreenshotService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = ClipboardHistoryStore(limit: settings.historyLimit, imageLimit: settings.imageLimit)
        let monitor = PasteboardMonitor(store: store)
        let panelController = HistoryPanelController(store: store)

        self.monitor = monitor
        historyStore = store
        self.panelController = panelController
        let screenshotService = RegionScreenshotService(store: store)
        self.screenshotService = screenshotService
        if settings.monitoringEnabled { monitor.start() }

        shortcutCoordinator.start(settings: settings) {
            panelController.toggle()
        } screenshotAction: {
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
