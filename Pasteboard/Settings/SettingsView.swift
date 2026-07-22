import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            HStack(spacing: 16) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .accessibilityLabel("Pasteboard application icon")
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppConfiguration.productName)
                        .font(.title2.weight(.semibold))
                    Text("Native, local-only clipboard history")
                        .foregroundStyle(.secondary)
                }
            }
            Divider()
            LabeledContent("History shortcut", value: AppConfiguration.defaultHistoryShortcut.displayName)
            LabeledContent("Screenshot shortcut", value: AppConfiguration.defaultScreenshotShortcut.displayName)
            LabeledContent("History limit", value: "\(AppConfiguration.defaultHistoryLimit)")
        }
        .padding()
        .frame(width: 440)
    }
}
