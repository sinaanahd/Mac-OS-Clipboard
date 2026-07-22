import SwiftUI

@main
struct PasteboardApp: App {
    var body: some Scene {
        WindowGroup(AppConfiguration.productName) {
            ContentView()
                .frame(minWidth: VisualConfiguration.panelSize.width,
                       minHeight: VisualConfiguration.panelSize.height)
        }
        Settings {
            SettingsView()
        }
    }
}
