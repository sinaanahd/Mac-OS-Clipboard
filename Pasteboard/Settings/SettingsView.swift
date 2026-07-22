import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            LabeledContent("History shortcut", value: AppConfiguration.defaultHistoryShortcut.displayName)
            LabeledContent("Screenshot shortcut", value: AppConfiguration.defaultScreenshotShortcut.displayName)
            LabeledContent("History limit", value: "\(AppConfiguration.defaultHistoryLimit)")
        }
        .padding()
        .frame(width: 420)
    }
}
