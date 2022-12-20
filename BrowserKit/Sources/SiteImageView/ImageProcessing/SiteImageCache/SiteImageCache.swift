// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Kingfisher
import UIKit

/// Handles caching of images. Will cache following the different image type. So for a given domain you can get different image type.
protocol SiteImageCache {
    /// Get the image depending on the image type
    /// - Parameters:
    ///   - domain: The domain to retrieve the image from
    ///   - type: The image type to retrieve the image from the cache
    /// - Returns: The image from the cache or throws an error if it could not retrieve it
    func getImageFromCache(domain: ImageDomain,
                           type: SiteImageType) async throws -> UIImage

    /// Cache an image into the right cache depending on it's type
    /// - Parameters:
    ///   - image: The image to cache
    ///   - domain: The image domain
    ///   - type: The image type
    func cacheImage(image: UIImage,
                    domain: ImageDomain,
                    type: SiteImageType) async
}

actor DefaultSiteImageCache: SiteImageCache {
    private let imageCache: DefaultImageCache

    init(imageCache: DefaultImageCache = ImageCache.default) {
        self.imageCache = imageCache
    }

    func getImageFromCache(domain: ImageDomain, type: SiteImageType) async throws -> UIImage {
        let key = cacheKey(from: domain, type: type)
        do {
            let result = try await imageCache.retrieveImage(forKey: key)
            guard let image = result else {
                throw SiteImageError.unableToRetrieveFromCache("Image was nil")
            }
            return image
        } catch let error as KingfisherError {
            throw SiteImageError.unableToRetrieveFromCache(error.errorDescription ?? "No description")
        }
    }

    func cacheImage(image: UIImage, domain: ImageDomain, type: SiteImageType) async {
        let key = cacheKey(from: domain, type: type)
        imageCache.store(image: image, forKey: key)
    }

    private func cacheKey(from domain: ImageDomain, type: SiteImageType) -> String {
        return "\(domain.baseDomain)-\(type.rawValue)"
    }
}
