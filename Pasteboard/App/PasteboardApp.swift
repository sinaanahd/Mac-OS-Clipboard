import SwiftUI

@main
struct PasteboardApp: App {
    @StateObject private var historyStore: ClipboardHistoryStore
    private let monitor: PasteboardMonitor

    init() {
        let store = ClipboardHistoryStore()
        _historyStore = StateObject(wrappedValue: store)
        monitor = PasteboardMonitor(store: store)
        monitor.start()
    }

    var body: some Scene {
        WindowGroup(AppConfiguration.productName) {
            ContentView(store: historyStore)
                .frame(minWidth: VisualConfiguration.panelSize.width,
                       minHeight: VisualConfiguration.panelSize.height)
        }
        Settings {
            SettingsView()
        }
    }
}
