import AppKit
import ImageIO

enum ThumbnailRenderer {
    static func makePNGData(from url: URL, maxPixelSize: Int) -> Data? {
        guard maxPixelSize > 0,
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { return nil }
        return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    }
}

@MainActor
final class ThumbnailService {
    private let cache = NSCache<NSURL, NSImage>()

    init() {
        cache.countLimit = 100
    }

    func thumbnail(for url: URL, maxPixelSize: Int) async -> NSImage? {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        let data = await Task.detached(priority: .utility) {
            ThumbnailRenderer.makePNGData(from: url, maxPixelSize: maxPixelSize)
        }.value
        guard let data, let image = NSImage(data: data) else { return nil }
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
