import AppKit
import Carbon.HIToolbox
import SwiftUI

struct ShortcutRecorder: NSViewRepresentable {
    let shortcut: KeyboardShortcut?
    let onRecord: (KeyboardShortcut) -> Void
    let onClear: () -> Void
    let onInvalid: () -> Void

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        let button = ShortcutRecorderButton()
        button.onRecord = onRecord
        button.onClear = onClear
        button.onInvalid = onInvalid
        button.shortcut = shortcut
        return button
    }

    func updateNSView(_ button: ShortcutRecorderButton, context: Context) {
        button.onRecord = onRecord
        button.onClear = onClear
        button.onInvalid = onInvalid
        if !button.isRecording { button.shortcut = shortcut }
    }
}

final class ShortcutRecorderButton: NSButton {
    var shortcut: KeyboardShortcut? { didSet { refreshTitle() } }
    var onRecord: ((KeyboardShortcut) -> Void)?
    var onClear: (() -> Void)?
    var onInvalid: (() -> Void)?
    private(set) var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        bezelStyle = .rounded
        target = self
        action = #selector(beginRecording)
        setAccessibilityLabel("Keyboard shortcut")
        refreshTitle()
    }

    required init?(coder: NSCoder) { nil }
    override var acceptsFirstResponder: Bool { true }

    @objc private func beginRecording() {
        isRecording = true
        title = "Type shortcut…"
        window?.makeFirstResponder(self)
        setAccessibilityValue("Recording. Press a key combination, Escape to cancel, or Delete to remove.")
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            finishRecording()
            return
        }
        if event.keyCode == UInt16(kVK_Delete) || event.keyCode == UInt16(kVK_ForwardDelete) {
            onClear?()
            finishRecording()
            return
        }
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard let candidate = KeyboardShortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers),
              candidate.isStructurallyValid else {
            NSSound.beep()
            onInvalid?()
            return
        }
        onRecord?(candidate)
        finishRecording()
    }

    override func resignFirstResponder() -> Bool {
        finishRecording()
        return super.resignFirstResponder()
    }

    private func finishRecording() {
        isRecording = false
        refreshTitle()
    }

    private func refreshTitle() {
        title = shortcut?.displayName ?? "Not Set"
        setAccessibilityValue(title)
    }
}
