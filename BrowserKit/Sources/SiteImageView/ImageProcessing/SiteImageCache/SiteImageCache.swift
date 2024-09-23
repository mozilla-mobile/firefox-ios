// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Kingfisher
import UIKit

/// Caches images for specific `SiteImageType`s. 
/// - Note: Different `SiteImageType`s will return different images. The type is appended to the cache key.
protocol SiteImageCache {
    /// Retrieves an image from the cache depending on the type.
    /// - Parameters:
    ///   - cacheKey: The cache key for the image.
    ///   - type: The image type to retrieve from the cache.
    /// - Returns: The image from the cache.
    /// - Throws: An error if the image cannot be retrieved.
    func getImage(cacheKey: String, type: SiteImageType) async throws -> UIImage

    /// Stores an image in the cache.
    /// - Parameters:
    ///   - image: The image to cache.
    ///   - cacheKey: The cache key for the image.
    ///   - type: The image type to save to the cache.
    func cacheImage(image: UIImage,
                    cacheKey: String,
                    type: SiteImageType) async

    /// Clears the image cache.
    func clear() async
}

actor DefaultSiteImageCache: SiteImageCache {
    private let imageCache: DefaultImageCache

    init(imageCache: DefaultImageCache = ImageCache.default) {
        self.imageCache = imageCache
    }

    func getImage(cacheKey: String, type: SiteImageType) async throws -> UIImage {
        let key = createCacheKey(cacheKey, forType: type)
        do {
            guard let image = try await imageCache.retrieve(forKey: key) else {
                throw SiteImageError.unableToRetrieveFromCache("Image was nil")
            }
            return image
        } catch let error as KingfisherError {
            throw SiteImageError.unableToRetrieveFromCache(error.errorDescription ?? "No description")
        }
    }

    func cacheImage(image: UIImage, cacheKey: String, type: SiteImageType) async {
        let key = createCacheKey(cacheKey, forType: type)
        imageCache.store(image: image, forKey: key)
    }

    func clear() async {
        imageCache.clear()
    }

    private func createCacheKey(_ cacheKey: String, forType type: SiteImageType) -> String {
        return "\(cacheKey)-\(type.rawValue)"
    }
}
