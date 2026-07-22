import AppKit
import QuartzCore
import SwiftUI

private final class HistoryPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class HistoryPanelController: NSObject, NSWindowDelegate {
    private let panel: HistoryPanel
    private let automaticPaste: AutomaticPasteService
    private let presentation: HistoryPanelPresentation
    private let settings: AppSettings
    private let thumbnailService = ThumbnailService()
    private var previousApplication: NSRunningApplication?
    private var presentationGeneration = 0

    init(store: ClipboardHistoryStore,
         settings: AppSettings,
         automaticPaste: AutomaticPasteService = AutomaticPasteService()) {
        self.automaticPaste = automaticPaste
        self.settings = settings
        presentation = HistoryPanelPresentation()
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
            rootView: ContentView(store: store, presentation: presentation,
                                  thumbnailService: thumbnailService) { [weak self] in
                self?.completeSelection()
            }
                .frame(width: AppConfiguration.panelSize.width,
                       height: AppConfiguration.panelSize.height)
        )
    }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        presentation.refresh()
        let currentApplication = NSWorkspace.shared.frontmostApplication
        if currentApplication?.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApplication = currentApplication
        }
        positionPanel()
        let targetOrigin = panel.frame.origin
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        presentationGeneration += 1
        panel.alphaValue = 0
        if !reduceMotion {
            panel.setFrameOrigin(NSPoint(x: targetOrigin.x, y: targetOrigin.y - 4))
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKey()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = VisualConfiguration.quickAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
            if !reduceMotion { panel.animator().setFrameOrigin(targetOrigin) }
        }
    }

    func hide() {
        guard panel.isVisible else { return }
        presentationGeneration += 1
        let generation = presentationGeneration
        panel.resignKey()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = VisualConfiguration.panelDismissDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self, self.presentationGeneration == generation else { return }
                self.panel.orderOut(nil)
                self.panel.alphaValue = 1
            }
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func completeSelection() {
        hide()
        guard settings.automaticPasteEnabled else { return }
        guard automaticPaste.hasPermission else {
            explainAccessibilityPermission()
            return
        }
        guard let previousApplication else { return }
        Task { @MainActor in
            _ = await automaticPaste.paste {
                previousApplication.activate()
            } isTargetFrontmost: {
                NSWorkspace.shared.frontmostApplication?.processIdentifier
                    == previousApplication.processIdentifier
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

    func windowDidMove(_ notification: Notification) {
        guard settings.panelPosition == .rememberLastPosition else { return }
        settings.lastPanelOrigin = PersistedPanelOrigin(panel.frame.origin)
    }

    private func positionPanel() {
        switch settings.panelPosition {
        case .nearPointer:
            positionNearPointer()
        case .activeScreenCenter:
            guard let frame = activeVisibleFrame() else { return }
            panel.setFrameOrigin(constrainedOrigin(
                NSPoint(x: frame.midX - panel.frame.width / 2,
                        y: frame.midY - panel.frame.height / 2), in: frame
            ))
        case .rememberLastPosition:
            guard let frame = activeVisibleFrame() else { return }
            let origin = settings.lastPanelOrigin?.point
                ?? NSPoint(x: frame.midX - panel.frame.width / 2,
                           y: frame.midY - panel.frame.height / 2)
            panel.setFrameOrigin(constrainedOrigin(origin, in: frame))
        }
    }

    private func activeVisibleFrame() -> NSRect? {
        let pointer = NSEvent.mouseLocation
        return (NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) } ?? NSScreen.main)?.visibleFrame
    }

    private func constrainedOrigin(_ origin: NSPoint, in frame: NSRect) -> NSPoint {
        NSPoint(x: min(max(origin.x, frame.minX), frame.maxX - panel.frame.width),
                y: min(max(origin.y, frame.minY), frame.maxY - panel.frame.height))
    }
}
