import Foundation

enum ScreenshotFilenameGenerator {
    static func filename(date: Date = .now, id: UUID = UUID()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = AppConfiguration.screenshotFilenameDateFormat
        return "\(AppConfiguration.screenshotFilenamePrefix)-\(formatter.string(from: date))-\(id.uuidString).png"
    }
}
