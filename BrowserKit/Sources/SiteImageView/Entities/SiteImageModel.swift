// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Stores information related to an image request inside SiteImageView.
public struct SiteImageModel {
    // A unique ID to tie the request to a certain image view
    let id: UUID

    // The image type expected when making a request
    let imageType: SiteImageType

    // Represents the website (not the associated image resource)
    let siteURL: URL

    // Used to cache any resources related to this request
    let cacheKey: String

    // The bundled resource or remote URL (e.g. faviconURL, preferrably high resolution) for this image.
    var siteResource: SiteResource?

    // Loaded image asset
    public var image: UIImage?

    public init(id: UUID,
                imageType: SiteImageType,
                siteURL: URL,
                siteResource: SiteResource? = nil,
                image: UIImage? = nil) {
        self.id = id
        self.imageType = imageType
        self.siteURL = siteURL
        if case .favicon = imageType, case .remoteURL(let faviconURL) = siteResource {
            // If we already have a favicon url, use the url as the cache key.
            // This is a special case where we want to use the exact URL that's provided (e.g. sponsored site, default
            // top sites without a bundled asset, etc.).
            self.cacheKey = faviconURL.absoluteString
        } else {
            self.cacheKey = SiteImageModel.generateCacheKey(siteURL: siteURL, type: imageType)
        }
        self.siteResource = siteResource
        self.image = image
    }

    /// Generates a cache key for the given image type by using its associated site URL.
    /// - Parameters:
    ///   - siteURL: The website with which this image is associated.
    ///   - type: The image type.
    /// - Returns: A cache key value for storing this image in an image cache.
    static func generateCacheKey(siteURL: URL, type: SiteImageType) -> String {
        switch type {
        case .heroImage:
            // Always use the full site URL as the cache key for hero images
            return siteURL.absoluteString
        case .favicon:
            // Use the domain as the key to avoid caching and fetching unnecessary duplicates
            return siteURL.shortDomain ?? siteURL.shortDisplayString
        }
    }
}
