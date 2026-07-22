import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
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
}
