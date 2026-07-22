import AppKit
import ImageIO
import XCTest
@testable import Pasteboard

final class ThumbnailServiceTests: XCTestCase {
    func testRendererDownsamplesLargeImage() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PasteboardThumbnailTests-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }
        let representation = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 800, pixelsHigh: 600,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0
        ))
        try XCTUnwrap(representation.representation(using: .png, properties: [:])).write(to: url)

        let thumbnailData = try XCTUnwrap(
            ThumbnailRenderer.makePNGData(from: url, maxPixelSize: 64)
        )
        let source = try XCTUnwrap(CGImageSourceCreateWithData(thumbnailData as CFData, nil))
        let properties = try XCTUnwrap(
            CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        )
        let width = try XCTUnwrap(properties[kCGImagePropertyPixelWidth] as? Int)
        let height = try XCTUnwrap(properties[kCGImagePropertyPixelHeight] as? Int)
        XCTAssertLessThanOrEqual(max(width, height), 64)
    }
}
