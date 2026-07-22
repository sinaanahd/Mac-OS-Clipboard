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
        NSAnimationContext.runAnimationGroup { context in
            context.duration = VisualConfiguration.panelDismissDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self, self.presentationGeneration == generation else { return }
                // orderOut performs the key-window transition. Calling resignKey
                // here would re-enter windowDidResignKey when Settings becomes key.
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

    func windowDidMove(_ notification: Notification) {
        guard settings.panelPosition == .rememberLastPosition else { return }
        settings.lastPanelOrigin = PersistedPanelOrigin(panel.frame.origin)
    }

    private func positionPanel() {
        let pointer = NSEvent.mouseLocation
        guard let frame = activeVisibleFrame() else { return }
        panel.setFrameOrigin(PanelPlacement.origin(
            preference: settings.panelPosition,
            pointer: pointer,
            panelSize: panel.frame.size,
            visibleFrame: frame,
            rememberedOrigin: settings.lastPanelOrigin?.point
        ))
    }

    private func activeVisibleFrame() -> NSRect? {
        let pointer = NSEvent.mouseLocation
        return (NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) } ?? NSScreen.main)?.visibleFrame
    }
}
