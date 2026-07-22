import AppKit
import SwiftUI

private final class HistoryPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class HistoryPanelController: NSObject, NSWindowDelegate {
    private let panel: HistoryPanel
    private let automaticPaste: AutomaticPasteService
    private var previousApplication: NSRunningApplication?

    init(store: ClipboardHistoryStore,
         automaticPaste: AutomaticPasteService = AutomaticPasteService()) {
        self.automaticPaste = automaticPaste
        panel = HistoryPanel(
            contentRect: NSRect(origin: .zero, size: AppConfiguration.panelSize),
            styleMask: [.titled, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init()

        panel.title = AppConfiguration.productName
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .windowBackgroundColor
        panel.delegate = self
        panel.contentViewController = NSHostingController(
            rootView: ContentView(store: store) { [weak self] in self?.completeSelection() }
                .frame(width: AppConfiguration.panelSize.width,
                       height: AppConfiguration.panelSize.height)
        )
    }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        let currentApplication = NSWorkspace.shared.frontmostApplication
        if currentApplication?.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApplication = currentApplication
        }
        positionNearPointer()
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func completeSelection() {
        hide()
        guard AppConfiguration.defaultAutomaticPasteEnabled else { return }
        guard automaticPaste.hasPermission else {
            explainAccessibilityPermission()
            return
        }
        guard let previousApplication else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfiguration.automaticPasteDelay) {
            _ = self.automaticPaste.paste {
                previousApplication.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }

    private func explainAccessibilityPermission() {
        let alert = NSAlert()
        alert.messageText = "Allow Pasteboard to paste automatically?"
        alert.informativeText = "Pasteboard needs Accessibility access to send Command-V to the app you were using. Your clipboard data stays on this Mac. The selected item is already copied and can be pasted manually."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")
        if alert.runModal() == .alertFirstButtonReturn {
            automaticPaste.requestPermission()
        }
    }

    private func positionNearPointer() {
        let pointer = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) } ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }
        let x = min(max(pointer.x - panel.frame.width / 2, visibleFrame.minX),
                    visibleFrame.maxX - panel.frame.width)
        let y = min(max(pointer.y - panel.frame.height, visibleFrame.minY),
                    visibleFrame.maxY - panel.frame.height)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
