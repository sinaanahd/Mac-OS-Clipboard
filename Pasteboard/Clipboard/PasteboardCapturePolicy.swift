import Foundation

enum PasteboardCapturePolicy {
    static func permitsCapture(
        monitoringEnabled: Bool,
        frontmostBundleIdentifier: String?,
        excludedBundleIdentifiers: Set<String>
    ) -> Bool {
        guard monitoringEnabled else { return false }
        guard let frontmostBundleIdentifier else { return true }
        return !excludedBundleIdentifiers.contains(frontmostBundleIdentifier)
    }
}
