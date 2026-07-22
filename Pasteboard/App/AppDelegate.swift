import AppKit
import Combine
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let settings = AppSettings()
    let shortcutCoordinator = ShortcutCoordinator()
    let storageUsage = StorageUsageService()
    private var historyStore: ClipboardHistoryStore?
    private var monitor: PasteboardMonitor?
    private var panelController: HistoryPanelController?
    private var screenshotService: RegionScreenshotService?
    @Published private(set) var launchAtLoginError: String?
    private var cancellables: Set<AnyCancellable> = []
    private var expirationTimer: Timer?
    private var applyingLaunchAtLogin = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = ClipboardHistoryStore(limit: settings.historyLimit, imageLimit: settings.imageLimit)
        let monitor = PasteboardMonitor(store: store, settings: settings)
        let panelController = HistoryPanelController(store: store, settings: settings)

        self.monitor = monitor
        historyStore = store
        self.panelController = panelController
        let screenshotService = RegionScreenshotService(store: store, settings: settings)
        self.screenshotService = screenshotService
        if settings.monitoringEnabled { monitor.start() }

        shortcutCoordinator.start(settings: settings) {
            panelController.toggle()
        } screenshotAction: {
            screenshotService.captureRegion()
        }
        configureRuntimeSettings(store: store, monitor: monitor)
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stop()
        expirationTimer?.invalidate()
    }

    func showHistory() {
        panelController?.show()
    }

    func captureRegion() {
        screenshotService?.captureRegion()
    }

    func confirmClearHistory() {
        guard let historyStore, !historyStore.entries.isEmpty else { return }
        let alert = NSAlert()
        alert.messageText = "Clear Clipboard History?"
        alert.informativeText = "This removes every saved clipboard entry, including pinned items, and Pasteboard-owned image copies. Original Finder files will not be deleted."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear History")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        historyStore.clear()
        storageUsage.refresh()
    }

    func confirmClearUnpinnedHistory() {
        guard let historyStore else { return }
        let count = historyStore.entries.filter { !$0.isPinned }.count
        guard count > 0 else { return }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Clear \(count) Unpinned Item\(count == 1 ? "" : "s")?"
        alert.informativeText = "Pinned entries will remain. Pasteboard-owned image copies for removed entries will be deleted; original Finder files will not."
        alert.addButton(withTitle: "Clear Unpinned")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        historyStore.clearUnpinned()
        storageUsage.refresh()
    }

    func openStorageFolder() {
        try? FileManager.default.createDirectory(
            at: AppConfiguration.applicationSupportURL,
            withIntermediateDirectories: true
        )
        NSWorkspace.shared.open(AppConfiguration.applicationSupportURL)
    }

    func resetAllSettings(using coordinator: ShortcutCoordinator) {
        guard let historyStore else { return }
        let removals = historyStore.removalCount(
            historyLimit: AppConfiguration.defaultHistoryLimit,
            imageLimit: AppConfiguration.defaultImageLimit
        )
        let alert = NSAlert()
        alert.messageText = "Reset All Pasteboard Settings?"
        alert.informativeText = removals > 0
            ? "Defaults will remove \(removals) older unpinned entries. Pins remain. This cannot be undone."
            : "Shortcuts, limits, and behavior will return to their defaults. Clipboard history and pins remain."
        alert.addButton(withTitle: "Reset Settings")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        historyStore.updateLimits(historyLimit: AppConfiguration.defaultHistoryLimit,
                                  imageLimit: AppConfiguration.defaultImageLimit)
        coordinator.update(.history, to: AppConfiguration.defaultHistoryShortcut)
        coordinator.update(.screenshot, to: AppConfiguration.defaultScreenshotShortcut)
        settings.historyLimit = AppConfiguration.defaultHistoryLimit
        settings.imageLimit = AppConfiguration.defaultImageLimit
        settings.automaticPasteEnabled = AppConfiguration.defaultAutomaticPasteEnabled
        settings.launchAtLoginEnabled = false
        settings.expiration = .never
        settings.panelPosition = .nearPointer
        settings.lastPanelOrigin = nil
        settings.screenshotBehavior = .historyAndClipboard
        settings.monitoringEnabled = true
        settings.excludedBundleIdentifiers = []
        storageUsage.refresh()
    }

    func requestHistoryLimit(_ proposedValue: Int) {
        guard let historyStore else { return }
        let value = AppSettings.normalizedHistoryLimit(proposedValue)
        guard value != settings.historyLimit else { return }
        let removals = historyStore.removalCount(historyLimit: value,
                                                  imageLimit: settings.imageLimit)
        guard confirmLimitChange(value: value, removals: removals, isImageLimit: false) else { return }
        historyStore.updateLimits(historyLimit: value, imageLimit: settings.imageLimit)
        settings.historyLimit = value
        storageUsage.refresh()
    }

    func requestImageLimit(_ proposedValue: Int) {
        guard let historyStore else { return }
        let value = AppSettings.normalizedImageLimit(proposedValue)
        guard value != settings.imageLimit else { return }
        let removals = historyStore.removalCount(historyLimit: settings.historyLimit,
                                                  imageLimit: value)
        guard confirmLimitChange(value: value, removals: removals, isImageLimit: true) else { return }
        historyStore.updateLimits(historyLimit: settings.historyLimit, imageLimit: value)
        settings.imageLimit = value
        storageUsage.refresh()
    }

    private func configureRuntimeSettings(store: ClipboardHistoryStore, monitor: PasteboardMonitor) {
        applyingLaunchAtLogin = true
        settings.launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        applyingLaunchAtLogin = false

        settings.$monitoringEnabled.dropFirst().sink { enabled in
            if enabled { monitor.start() } else { monitor.stop() }
        }.store(in: &cancellables)
        settings.$expiration.dropFirst().sink { option in
            store.cleanup(expirationPolicy: option.policy)
        }.store(in: &cancellables)
        settings.$launchAtLoginEnabled.dropFirst().sink { [weak self] enabled in
            self?.applyLaunchAtLogin(enabled)
        }.store(in: &cancellables)

        store.cleanup(expirationPolicy: settings.expiration.policy)
        expirationTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                store.cleanup(expirationPolicy: self.settings.expiration.policy)
            }
        }
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        guard !applyingLaunchAtLogin else { return }
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            launchAtLoginError = SMAppService.mainApp.status == .requiresApproval
                ? "Approve Pasteboard in System Settings › General › Login Items."
                : nil
        } catch {
            launchAtLoginError = "macOS could not update the login item. Try again in System Settings."
            applyingLaunchAtLogin = true
            settings.launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            applyingLaunchAtLogin = false
        }
    }

    private func confirmLimitChange(value: Int, removals: Int, isImageLimit: Bool) -> Bool {
        let warningThreshold = isImageLimit ? AppSettings.Limits.imageWarning
                                            : AppSettings.Limits.historyWarning
        if value > warningThreshold {
            let warning = NSAlert()
            warning.messageText = "Use a large \(isImageLimit ? "image" : "history") limit?"
            warning.informativeText = "Large histories may increase memory usage, storage usage, search time, and panel loading time. Pasteboard does not guarantee optimal performance above the recommended range."
            warning.addButton(withTitle: "Use \(value)")
            warning.addButton(withTitle: "Cancel")
            guard warning.runModal() == .alertFirstButtonReturn else { return false }
        }
        guard removals > 0 else { return true }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Reduce \(isImageLimit ? "image" : "history") limit to \(value)?"
        alert.informativeText = "This will remove \(removals) older unpinned clipboard entr\(removals == 1 ? "y" : "ies"). Pinned entries will remain. Original Finder files are never removed."
        alert.addButton(withTitle: "Reduce Limit")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
}
