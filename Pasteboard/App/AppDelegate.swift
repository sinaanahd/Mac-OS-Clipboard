import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var monitor: PasteboardMonitor?
    private var panelController: HistoryPanelController?
    private var historyHotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = ClipboardHistoryStore()
        let monitor = PasteboardMonitor(store: store)
        let panelController = HistoryPanelController(store: store)

        self.monitor = monitor
        self.panelController = panelController
        monitor.start()

        historyHotKey = try? GlobalHotKey(shortcut: AppConfiguration.defaultHistoryShortcut) {
            panelController.toggle()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stop()
    }

    func showHistory() {
        panelController?.show()
    }
}
