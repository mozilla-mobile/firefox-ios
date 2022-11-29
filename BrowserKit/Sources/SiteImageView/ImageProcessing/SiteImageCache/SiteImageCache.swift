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
    /// - Returns: The image from the cache or an error if it could not retrieve it
    func getImageFromCache(domain: String,
                           type: SiteImageType) async -> Result<UIImage, ImageError>

    /// Cache an image into the right cache depending on it's type
    /// - Parameters:
    ///   - image: The image to cache
    ///   - domain: The image domain
    ///   - type: The image type
    ///   Returns:  Calls completes with success or returns an error why the caching failed
    func cacheImage(image: UIImage,
                    domain: String,
                    type: SiteImageType) async -> Result<(), ImageError>
}

actor DefaultSiteImageCache: SiteImageCache {

    private let imageCache: DefaultImageCache

    init(imageCache: DefaultImageCache = ImageCache.default) {
        self.imageCache = imageCache
    }

    func getImageFromCache(domain: String, type: SiteImageType) async -> Result<UIImage, ImageError> {
        let key = cacheKey(from: domain, type: type)
        let result = await imageCache.retrieveImage(forKey: key)

        switch result {
        case .success(let image):
            guard let image = image else {
                return .failure(ImageError.unableToRetrieveFromCache("Image was nil"))
            }
            return .success(image)

        case .failure(let error):
            return .failure(ImageError.unableToRetrieveFromCache(error.errorDescription ?? "No description"))
        }
    }

    func cacheImage(image: UIImage, domain: String, type: SiteImageType) async -> Result<(), ImageError> {
        let key = cacheKey(from: domain, type: type)
        let result = await imageCache.store(image: image, forKey: key)

        switch result {
        case .success:
            return .success(())

        case .failure(let error):
            return .failure(ImageError.unableToRetrieveFromCache(error.errorDescription ?? "No description"))
        }
    }

    private func cacheKey(from domain: String, type: SiteImageType) -> String {
        return "\(domain)-\(type.rawValue)"
    }
}
