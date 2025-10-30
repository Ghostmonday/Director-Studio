import Foundation
import UIKit
import AVFoundation

final class ThumbnailCache {
    static let shared = ThumbnailCache()
    
    private let cache = NSCache<NSURL, UIImage>()
    private let maxCacheSize = 20
    private var accessOrder: [URL] = []
    
    private init() {
        cache.countLimit = maxCacheSize
        cache.totalCostLimit = 50 * 1024 * 1024
    }
    
    func getThumbnail(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func setThumbnail(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
        
        if let index = accessOrder.firstIndex(of: url) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(url)
        
        if accessOrder.count > maxCacheSize {
            let oldest = accessOrder.removeFirst()
            cache.removeObject(forKey: oldest as NSURL)
        }
    }
    
    func generateThumbnail(for url: URL) async -> UIImage? {
        if let cached = getThumbnail(for: url) {
            return cached
        }
        
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        
        do {
            let cgImage = try await generator.image(at: CMTime(seconds: 0, preferredTimescale: 600)).image
            let image = UIImage(cgImage: cgImage)
            setThumbnail(image, for: url)
            return image
        } catch {
            return nil
        }
    }
}

