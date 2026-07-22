import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var shortcutCoordinator: ShortcutCoordinator
    @ObservedObject var runtime: AppDelegate
    @AppStorage(AppSettings.selectedPaneDefaultsKey) private var selectedPane = SettingsPane.general.rawValue

    var body: some View {
        TabView(selection: $selectedPane) {
            GeneralSettingsPane(settings: settings, runtime: runtime)
                .tabItem { Label("General", systemImage: "gear") }
                .tag(SettingsPane.general.rawValue)
            FeaturesSettingsPane(settings: settings, runtime: runtime)
                .tabItem { Label("Features", systemImage: "switch.2") }
                .tag(SettingsPane.features.rawValue)
            ShortcutsSettingsPane(settings: settings, coordinator: shortcutCoordinator)
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                .tag(SettingsPane.shortcuts.rawValue)
            PrivacyStorageSettingsPane(settings: settings, runtime: runtime,
                                       storageUsage: runtime.storageUsage)
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
    @ObservedObject var runtime: AppDelegate

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch Pasteboard at login", isOn: $settings.launchAtLoginEnabled)
                Text("Login-item registration is applied through macOS and may require approval.")
                    .font(.caption).foregroundStyle(.secondary)
                if let error = runtime.launchAtLoginError {
                    Text(error).font(.caption).foregroundStyle(.orange)
                }
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
    @ObservedObject var runtime: AppDelegate
    @State private var historyDraft = ""
    @State private var imageDraft = ""

    var body: some View {
        Form {
            Section("History") {
                Picker("Maximum unpinned items", selection: Binding(
                    get: { settings.historyLimit },
                    set: { runtime.requestHistoryLimit($0) }
                )) {
                    ForEach([50, 100, 200, 500, 1_000], id: \.self) { Text("\($0)").tag($0) }
                    if ![50, 100, 200, 500, 1_000].contains(settings.historyLimit) {
                        Text("Custom (\(settings.historyLimit))").tag(settings.historyLimit)
                    }
                }
                HStack {
                    TextField("Custom limit", text: $historyDraft)
                        .onSubmit { applyHistoryDraft() }
                    Button("Apply") { applyHistoryDraft() }
                }
                Text("Pinned items do not count against this limit.")
                    .font(.caption).foregroundStyle(.secondary)
                if settings.historyLimit > AppSettings.Limits.historyWarning { performanceWarning }
                Picker("Maximum unpinned images and screenshots", selection: Binding(
                    get: { settings.imageLimit },
                    set: { runtime.requestImageLimit($0) }
                )) {
                    ForEach([20, 50, 100, 250, 500], id: \.self) { Text("\($0)").tag($0) }
                    if ![20, 50, 100, 250, 500].contains(settings.imageLimit) {
                        Text("Custom (\(settings.imageLimit))").tag(settings.imageLimit)
                    }
                }
                HStack {
                    TextField("Custom image limit", text: $imageDraft)
                        .onSubmit { applyImageDraft() }
                    Button("Apply") { applyImageDraft() }
                }
                if settings.imageLimit > AppSettings.Limits.imageWarning { performanceWarning }
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
        .onAppear {
            historyDraft = String(settings.historyLimit)
            imageDraft = String(settings.imageLimit)
        }
    }

    private var performanceWarning: some View {
        Text("Large histories may increase memory, storage, search, and panel loading time. Performance above the recommended range is not guaranteed.")
            .font(.caption).foregroundStyle(.orange)
    }

    private func applyHistoryDraft() {
        guard let value = Int(historyDraft) else { historyDraft = String(settings.historyLimit); return }
        runtime.requestHistoryLimit(value)
        historyDraft = String(settings.historyLimit)
    }

    private func applyImageDraft() {
        guard let value = Int(imageDraft) else { imageDraft = String(settings.imageLimit); return }
        runtime.requestImageLimit(value)
        imageDraft = String(settings.imageLimit)
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
    @ObservedObject var runtime: AppDelegate
    @ObservedObject var storageUsage: StorageUsageService
    @State private var runningApplications: [RunningApplicationChoice] = []
    @State private var selectedBundleIdentifier = ""

    var body: some View {
        Form {
            Section("Recording") {
                Toggle("Record clipboard history", isOn: $settings.monitoringEnabled)
                Text(settings.monitoringEnabled ? "Clipboard history recording is active."
                                                : "Recording is paused; existing history is preserved.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Storage") {
                LabeledContent("Metadata", value: storageUsage.usage.formatted(storageUsage.usage.metadataBytes))
                LabeledContent("Image payloads", value: storageUsage.usage.formatted(storageUsage.usage.imageBytes))
                LabeledContent("Total", value: storageUsage.usage.formatted(storageUsage.usage.totalBytes))
                if storageUsage.isCalculating { ProgressView().controlSize(.small) }
                HStack {
                    Button("Refresh Usage") { storageUsage.refresh() }
                    Button("Open Storage Folder") { runtime.openStorageFolder() }
                }
                HStack {
                    Button("Clear Unpinned History…") { runtime.confirmClearUnpinnedHistory() }
                    Button("Clear All History…", role: .destructive) { runtime.confirmClearHistory() }
                }
            }
            Section("Excluded Applications") {
                HStack {
                    Picker("Running application", selection: $selectedBundleIdentifier) {
                        Text("Choose an application").tag("")
                        ForEach(runningApplications) { app in
                            Text(app.name).tag(app.bundleIdentifier)
                        }
                    }
                    Button("Add") {
                        guard !selectedBundleIdentifier.isEmpty else { return }
                        settings.excludedBundleIdentifiers.insert(selectedBundleIdentifier)
                        selectedBundleIdentifier = ""
                    }
                    .disabled(selectedBundleIdentifier.isEmpty)
                }
                ForEach(settings.excludedBundleIdentifiers.sorted(), id: \.self) { identifier in
                    ExcludedApplicationRow(bundleIdentifier: identifier) {
                        settings.excludedBundleIdentifiers.remove(identifier)
                    }
                }
                if settings.excludedBundleIdentifiers.isEmpty {
                    Text("No applications are excluded.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section {
                Text("Clipboard data and preferences remain local to this Mac. No analytics or clipboard content is transmitted.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Reset All Settings…") { runtime.resetAllSettings(using: runtime.shortcutCoordinator) }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            reloadRunningApplications()
            storageUsage.refresh()
        }
    }

    private func reloadRunningApplications() {
        runningApplications = NSWorkspace.shared.runningApplications.compactMap { app in
            guard app.activationPolicy == .regular,
                  let identifier = app.bundleIdentifier,
                  identifier != Bundle.main.bundleIdentifier else { return nil }
            return RunningApplicationChoice(bundleIdentifier: identifier,
                                            name: app.localizedName ?? identifier)
        }.reduce(into: [String: RunningApplicationChoice]()) { result, app in
            result[app.bundleIdentifier] = app
        }
            .values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

private struct RunningApplicationChoice: Identifiable {
    let bundleIdentifier: String
    let name: String
    var id: String { bundleIdentifier }
}

private struct ExcludedApplicationRow: View {
    let bundleIdentifier: String
    let remove: () -> Void

    var body: some View {
        HStack {
            Image(nsImage: icon).resizable().frame(width: 24, height: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(name)
                Text(bundleIdentifier).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Remove", action: remove).buttonStyle(.borderless)
                .accessibilityLabel("Remove \(name) from excluded applications")
        }
    }

    private var applicationURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    private var name: String {
        applicationURL?.deletingPathExtension().lastPathComponent ?? bundleIdentifier
    }

    private var icon: NSImage {
        applicationURL.map { NSWorkspace.shared.icon(forFile: $0.path) }
            ?? NSImage(systemSymbolName: "app", accessibilityDescription: nil)!
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
