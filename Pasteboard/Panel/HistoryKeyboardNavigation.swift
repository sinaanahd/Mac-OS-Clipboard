import Foundation

enum HistoryNavigationDirection {
    case previous
    case next
}

enum HistoryKeyboardNavigation {
    static func movedSelection<ID: Equatable>(
        current: ID?,
        ids: [ID],
        direction: HistoryNavigationDirection
    ) -> ID? {
        guard !ids.isEmpty else { return nil }
        guard let current, let index = ids.firstIndex(of: current) else {
            return direction == .next ? ids.first : ids.last
        }

        switch direction {
        case .previous:
            return ids[max(ids.startIndex, index - 1)]
        case .next:
            return ids[min(ids.index(before: ids.endIndex), index + 1)]
        }
    }
}
