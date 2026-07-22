import AppKit
import SwiftUI

@main
struct PasteboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        NSImage(named: "MenuBarIcon")?.isTemplate = true
    }

    var body: some Scene {
        MenuBarExtra(AppConfiguration.productName, image: "MenuBarIcon") {
            Button("Show History") { appDelegate.showHistory() }
                .keyboardShortcut("v", modifiers: [.option])
            Button("Capture Region") { appDelegate.captureRegion() }
                .keyboardShortcut("4", modifiers: [.option, .shift])
            Button("About Pasteboard") { NSApplication.shared.orderFrontStandardAboutPanel(nil) }
            SettingsLink()
            Divider()
            Button("Clear History…") { appDelegate.confirmClearHistory() }
            Divider()
            Button("Quit Pasteboard") { NSApplication.shared.terminate(nil) }
        }

        Settings {
            SettingsView()
        }
    }
}
