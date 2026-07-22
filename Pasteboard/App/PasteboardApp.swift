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
            Button("Capture Region") { appDelegate.captureRegion() }
            Button("About Pasteboard") { NSApplication.shared.orderFrontStandardAboutPanel(nil) }
            SettingsLink()
                .keyboardShortcut(",", modifiers: [.command])
            Divider()
            Button("Clear History…") { appDelegate.confirmClearHistory() }
            Divider()
            Button("Quit Pasteboard") { NSApplication.shared.terminate(nil) }
        }

        Settings {
            SettingsView(settings: appDelegate.settings,
                         shortcutCoordinator: appDelegate.shortcutCoordinator)
        }
    }
}
