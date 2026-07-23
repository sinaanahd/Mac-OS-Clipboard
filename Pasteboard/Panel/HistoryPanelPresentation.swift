import Combine
import Foundation

@MainActor
final class HistoryPanelPresentation: ObservableObject {
    @Published private(set) var referenceDate: Date
    @Published var keyboardSelection: ClipboardEntry.ID?
    private(set) var isListFocused = false

    init(referenceDate: Date = .now) {
        self.referenceDate = referenceDate
    }

    func refresh(at date: Date = .now) {
        referenceDate = date
    }

    func setListFocused(_ focused: Bool) {
        isListFocused = focused
    }

    func resetKeyboardState() {
        keyboardSelection = nil
        isListFocused = false
    }
}

enum HistoryRelativeTimeFormatter {
    static func string(from date: Date, relativeTo referenceDate: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: max(date, referenceDate))
    }
}
