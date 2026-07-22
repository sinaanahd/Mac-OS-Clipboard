import AppKit

enum PanelPlacement {
    static func origin(
        preference: PanelPositionPreference,
        pointer: NSPoint,
        panelSize: NSSize,
        visibleFrame: NSRect,
        rememberedOrigin: NSPoint?
    ) -> NSPoint {
        let proposed: NSPoint
        switch preference {
        case .nearPointer:
            proposed = NSPoint(x: pointer.x - panelSize.width / 2,
                               y: pointer.y - panelSize.height)
        case .activeScreenCenter:
            proposed = NSPoint(x: visibleFrame.midX - panelSize.width / 2,
                               y: visibleFrame.midY - panelSize.height / 2)
        case .rememberLastPosition:
            proposed = rememberedOrigin ?? NSPoint(
                x: visibleFrame.midX - panelSize.width / 2,
                y: visibleFrame.midY - panelSize.height / 2
            )
        }
        return constrained(proposed, panelSize: panelSize, to: visibleFrame)
    }

    private static func constrained(_ origin: NSPoint, panelSize: NSSize,
                                    to frame: NSRect) -> NSPoint {
        NSPoint(
            x: min(max(origin.x, frame.minX), frame.maxX - panelSize.width),
            y: min(max(origin.y, frame.minY), frame.maxY - panelSize.height)
        )
    }
}
