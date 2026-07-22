import ApplicationServices
import Foundation

protocol AccessibilityPermissionProviding: Sendable {
    var isTrusted: Bool { get }
    func requestAccess()
}

struct SystemAccessibilityPermission: AccessibilityPermissionProviding {
    var isTrusted: Bool { AXIsProcessTrusted() }

    func requestAccess() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}

protocol PasteEventPosting: Sendable {
    func postCommandV()
}

struct SystemPasteEventPoster: PasteEventPosting {
    func postCommandV() {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else { return }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

enum AutomaticPasteResult: Equatable {
    case pasted
    case permissionRequired
    case activationFailed
}

struct AutomaticPasteService: Sendable {
    private let permission: any AccessibilityPermissionProviding
    private let eventPoster: any PasteEventPosting

    init(permission: any AccessibilityPermissionProviding = SystemAccessibilityPermission(),
         eventPoster: any PasteEventPosting = SystemPasteEventPoster()) {
        self.permission = permission
        self.eventPoster = eventPoster
    }

    var hasPermission: Bool { permission.isTrusted }

    func requestPermission() {
        permission.requestAccess()
    }

    func paste(activateTarget: () -> Bool) -> AutomaticPasteResult {
        guard permission.isTrusted else { return .permissionRequired }
        guard activateTarget() else { return .activationFailed }
        eventPoster.postCommandV()
        return .pasted
    }
}
