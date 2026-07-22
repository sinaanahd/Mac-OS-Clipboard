import AppKit
import Foundation

enum PasteboardImageWriter {
    @discardableResult
    static func writePNG(_ data: Data, to pasteboard: NSPasteboard = .general) -> Bool {
        guard !data.isEmpty else { return false }
        pasteboard.clearContents()
        return pasteboard.setData(data, forType: .png)
    }
}
