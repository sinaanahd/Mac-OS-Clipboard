import Carbon.HIToolbox
import Foundation

enum GlobalHotKeyError: Error {
    case unsupportedKey
    case registrationFailed(OSStatus)
    case handlerInstallationFailed(OSStatus)
}

final class GlobalHotKey: @unchecked Sendable {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let action: @MainActor @Sendable () -> Void
    private let identifier: UInt32

    init(shortcut: KeyboardShortcut, identifier: UInt32 = 1,
         action: @escaping @MainActor @Sendable () -> Void) throws {
        guard let keyCode = shortcut.carbonKeyCode else { throw GlobalHotKeyError.unsupportedKey }
        self.action = action
        self.identifier = identifier

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let handlerStatus = InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return noErr }
            let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
            var eventIdentifier = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &eventIdentifier
            )
            let disposition = GlobalHotKey.eventDisposition(
                readStatus: status,
                eventIdentifier: eventIdentifier.id,
                registeredIdentifier: hotKey.identifier
            )
            guard disposition == noErr else { return disposition }
            Task { @MainActor in hotKey.action() }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandlerRef)
        guard handlerStatus == noErr else {
            throw GlobalHotKeyError.handlerInstallationFailed(handlerStatus)
        }

        let identifier = EventHotKeyID(signature: OSType(0x50535442), id: identifier)
        let registrationStatus = RegisterEventHotKey(keyCode, shortcut.carbonModifiers,
                                                     identifier, GetApplicationEventTarget(),
                                                     0, &hotKeyRef)
        guard registrationStatus == noErr else {
            if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
            throw GlobalHotKeyError.registrationFailed(registrationStatus)
        }
    }

    static func eventDisposition(readStatus: OSStatus,
                                 eventIdentifier: UInt32,
                                 registeredIdentifier: UInt32) -> OSStatus {
        guard readStatus == noErr, eventIdentifier == registeredIdentifier else {
            return OSStatus(eventNotHandledErr)
        }
        return noErr
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
    }
}
