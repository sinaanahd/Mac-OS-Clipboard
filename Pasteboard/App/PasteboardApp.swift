import SwiftUI

@main
struct PasteboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra(AppConfiguration.productName, systemImage: "clipboard") {
            Button("Show History") { appDelegate.showHistory() }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            Button("Capture Region") { appDelegate.captureRegion() }
                .keyboardShortcut("5", modifiers: [.control, .command, .shift])
            SettingsLink()
            Divider()
            Button("Quit Pasteboard") { NSApplication.shared.terminate(nil) }
        }

        Settings {
            SettingsView()
        }
    }
}
