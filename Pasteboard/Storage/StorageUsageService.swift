import Combine
import Foundation

struct StorageUsage: Equatable, Sendable {
    var metadataBytes: Int64 = 0
    var imageBytes: Int64 = 0
    var totalBytes: Int64 { metadataBytes + imageBytes }

    func formatted(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
    }
}

actor StorageUsageCalculator {
    func calculate(baseURL: URL) -> StorageUsage {
        let metadataURL = baseURL.appendingPathComponent(AppConfiguration.interimTextHistoryFilename)
        let imagesURL = baseURL.appendingPathComponent(
            AppConfiguration.imagePayloadDirectoryName, isDirectory: true
        )
        return StorageUsage(metadataBytes: fileSize(metadataURL),
                            imageBytes: directorySize(imagesURL))
    }

    private func fileSize(_ url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    private func directorySize(_ url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true else { continue }
            total += Int64(values.fileSize ?? 0)
        }
        return total
    }
}

@MainActor
final class StorageUsageService: ObservableObject {
    @Published private(set) var usage = StorageUsage()
    @Published private(set) var isCalculating = false
    private let calculator: StorageUsageCalculator

    init(calculator: StorageUsageCalculator = StorageUsageCalculator()) {
        self.calculator = calculator
    }

    func refresh() {
        guard !isCalculating else { return }
        isCalculating = true
        Task {
            usage = await calculator.calculate(baseURL: AppConfiguration.applicationSupportURL)
            isCalculating = false
        }
    }
}
