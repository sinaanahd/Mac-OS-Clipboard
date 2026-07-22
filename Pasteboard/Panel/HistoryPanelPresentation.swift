import Combine
import Foundation

@MainActor
final class HistoryPanelPresentation: ObservableObject {
    @Published private(set) var referenceDate: Date

    init(referenceDate: Date = .now) {
        self.referenceDate = referenceDate
    }

    func refresh(at date: Date = .now) {
        referenceDate = date
    }
}

enum HistoryRelativeTimeFormatter {
    static func string(from date: Date, relativeTo referenceDate: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: max(date, referenceDate))
    }
}
