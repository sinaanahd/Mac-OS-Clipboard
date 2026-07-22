import Foundation

struct ScreenshotCompletionPlan: Equatable, Sendable {
    let addsToHistory: Bool
    let copiesToClipboard: Bool
    let confirmationMessage: String

    init(behavior: ScreenshotCompletionBehavior) {
        switch behavior {
        case .historyAndClipboard:
            addsToHistory = true
            copiesToClipboard = true
            confirmationMessage = "Screenshot saved and copied"
        case .historyOnly:
            addsToHistory = true
            copiesToClipboard = false
            confirmationMessage = "Screenshot added to history"
        case .clipboardOnly:
            addsToHistory = false
            copiesToClipboard = true
            confirmationMessage = "Screenshot copied"
        }
    }
}
