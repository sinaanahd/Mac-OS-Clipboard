import Foundation

enum ScreenshotFileLoader {
    private static let pngSignature = Data([137, 80, 78, 71, 13, 10, 26, 10])

    nonisolated static func loadStablePNG(
        from url: URL,
        timeout: Duration,
        pollInterval: Duration
    ) async -> Data? {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        var previousByteCount: Int?

        while clock.now < deadline {
            if let data = try? Data(contentsOf: url), data.starts(with: pngSignature) {
                if previousByteCount == data.count { return data }
                previousByteCount = data.count
            }
            try? await Task.sleep(for: pollInterval)
        }
        return nil
    }
}
