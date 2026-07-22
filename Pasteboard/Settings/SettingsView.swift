import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var shortcutCoordinator: ShortcutCoordinator
    @AppStorage(AppSettings.selectedPaneDefaultsKey) private var selectedPane = SettingsPane.general.rawValue

    var body: some View {
        TabView(selection: $selectedPane) {
            GeneralSettingsPane(settings: settings)
                .tabItem { Label("General", systemImage: "gear") }
                .tag(SettingsPane.general.rawValue)
            FeaturesSettingsPane(settings: settings)
                .tabItem { Label("Features", systemImage: "switch.2") }
                .tag(SettingsPane.features.rawValue)
            ShortcutsSettingsPane(settings: settings, coordinator: shortcutCoordinator)
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                .tag(SettingsPane.shortcuts.rawValue)
            PrivacyStorageSettingsPane(settings: settings)
                .tabItem { Label("Privacy & Storage", systemImage: "hand.raised") }
                .tag(SettingsPane.privacyStorage.rawValue)
            AboutSettingsPane()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(SettingsPane.about.rawValue)
        }
        .frame(width: 560, height: 430)
        .onAppear {
            if SettingsPane(rawValue: selectedPane) == nil {
                selectedPane = SettingsPane.general.rawValue
            }
        }
    }
}

private struct GeneralSettingsPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch Pasteboard at login", isOn: $settings.launchAtLoginEnabled)
                Text("Login-item registration is applied through macOS and may require approval.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Clipboard") {
                Toggle("Automatically paste selected history items", isOn: $settings.automaticPasteEnabled)
                Text("When off, selecting an item copies it and closes history; press Command-V manually.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Record clipboard history", isOn: $settings.monitoringEnabled)
            }
            Section("Panel") {
                Picker("History panel position", selection: $settings.panelPosition) {
                    ForEach(PanelPositionPreference.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct FeaturesSettingsPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("History") {
                Stepper("Maximum unpinned items: \(settings.historyLimit)",
                        value: $settings.historyLimit,
                        in: AppSettings.Limits.history)
                Text("Pinned items do not count against this limit.")
                    .font(.caption).foregroundStyle(.secondary)
                Stepper("Maximum unpinned images: \(settings.imageLimit)",
                        value: $settings.imageLimit,
                        in: AppSettings.Limits.image)
                Picker("Automatically remove old unpinned entries", selection: $settings.expiration) {
                    ForEach(ExpirationOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            }
            Section("Screenshots") {
                Picker("After capturing a region", selection: $settings.screenshotBehavior) {
                    ForEach(ScreenshotCompletionBehavior.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct ShortcutsSettingsPane: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var coordinator: ShortcutCoordinator

    var body: some View {
        Form {
            shortcutRow("Show clipboard history", kind: .history,
                        shortcut: settings.historyShortcutEnabled ? settings.historyShortcut : nil)
            shortcutRow("Capture screen region", kind: .screenshot,
                        shortcut: settings.screenshotShortcutEnabled ? settings.screenshotShortcut : nil)
            Text("Click a shortcut, then type a new combination. Escape cancels; Delete removes it.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding()
    }

    @ViewBuilder
    private func shortcutRow(_ title: String, kind: ShortcutKind,
                             shortcut: KeyboardShortcut?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                ShortcutRecorder(shortcut: shortcut) { candidate in
                    coordinator.update(kind, to: candidate)
                } onClear: {
                    coordinator.update(kind, to: nil)
                } onInvalid: {
                    coordinator.reportInvalid(kind)
                }
                .frame(width: 145)
                Button("Reset") {
                    let fallback = kind == .history
                        ? AppConfiguration.defaultHistoryShortcut
                        : AppConfiguration.defaultScreenshotShortcut
                    coordinator.update(kind, to: fallback)
                }
            }
            if let error = coordinator.errors[kind] {
                Label(error.message, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Shortcut error: \(error.message)")
            } else if shortcut != nil && !coordinator.activeKinds.contains(kind) {
                Text("This shortcut is saved but currently unavailable.")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
    }
}

private struct PrivacyStorageSettingsPane: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Toggle("Record clipboard history", isOn: $settings.monitoringEnabled)
            LabeledContent("Excluded applications", value: "\(settings.excludedBundleIdentifiers.count)")
            Text("Clipboard data and preferences remain local to this Mac.")
                .font(.caption).foregroundStyle(.secondary)
            Button("Reset All Settings") { settings.resetAll() }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct AboutSettingsPane: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable().scaledToFit().frame(width: 88, height: 88)
                .accessibilityLabel("Pasteboard application icon")
            Text(AppConfiguration.productName).font(.title2.weight(.semibold))
            Text("Version \(AppConfiguration.marketingVersion) (Build \(AppConfiguration.buildNumber))")
                .foregroundStyle(.secondary)
            Text("Native, local-only clipboard history. No analytics or network transmission.")
                .multilineTextAlignment(.center)
            Text(AppConfiguration.applicationSupportURL.path)
                .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            Link("github.com/sinaanahd/Mac-OS-Clipboard",
                 destination: URL(string: "https://github.com/sinaanahd/Mac-OS-Clipboard")!)
            Text("Copyright © 2026 Sina Nahd").font(.caption).foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
