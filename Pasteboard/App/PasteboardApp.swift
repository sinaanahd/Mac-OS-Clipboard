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
            if !appDelegate.settings.monitoringEnabled {
                Label("History Recording Paused", systemImage: "pause.circle.fill")
            }
            Button("Show History") { appDelegate.showHistory() }
            Button("Capture Region") { appDelegate.captureRegion() }
            Toggle("Record Clipboard History", isOn: Binding(
                get: { appDelegate.settings.monitoringEnabled },
                set: { appDelegate.settings.monitoringEnabled = $0 }
            ))
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
                         shortcutCoordinator: appDelegate.shortcutCoordinator,
                         runtime: appDelegate)
        }
    }
}
