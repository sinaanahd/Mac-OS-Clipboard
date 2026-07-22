import AppKit
import SwiftUI

private final class HistoryPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class HistoryPanelController: NSObject, NSWindowDelegate {
    private let panel: HistoryPanel

    init(store: ClipboardHistoryStore) {
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
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = true
        panel.backgroundColor = .windowBackgroundColor
        panel.delegate = self
        panel.contentViewController = NSHostingController(
            rootView: ContentView(store: store) { [weak panel] in panel?.orderOut(nil) }
                .frame(width: AppConfiguration.panelSize.width,
                       height: AppConfiguration.panelSize.height)
        )
    }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        positionNearPointer()
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
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
