import AppKit
import SwiftUI

@MainActor
final class ConfirmationHUDController {
    private let panel: NSPanel
    private var hideTask: Task<Void, Never>?

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 52),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isReleasedWhenClosed = false
    }

    func show(_ message: String) {
        hideTask?.cancel()
        panel.contentViewController = NSHostingController(rootView: ConfirmationHUDView(message: message))
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
            ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: frame.midX - panel.frame.width / 2,
                                         y: frame.maxY - panel.frame.height - 28))
        }
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = VisualConfiguration.quickAnimationDuration
            panel.animator().alphaValue = 1
        }
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(VisualConfiguration.confirmationDuration))
            guard !Task.isCancelled, let self else { return }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = VisualConfiguration.panelDismissDuration
                self.panel.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                Task { @MainActor in
                    self?.panel.orderOut(nil)
                    self?.panel.alphaValue = 1
                }
            }
        }
    }
}

private struct ConfirmationHUDView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .confirmationSurface()
            .accessibilityElement(children: .combine)
    }
}

private extension View {
    @ViewBuilder
    func confirmationSurface() -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            background(.regularMaterial,
                       in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
