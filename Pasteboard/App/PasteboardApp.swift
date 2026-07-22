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
                .keyboardShortcut("v", modifiers: [.command, .shift])
            Button("Capture Region") { appDelegate.captureRegion() }
                .keyboardShortcut("5", modifiers: [.control, .command, .shift])
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
