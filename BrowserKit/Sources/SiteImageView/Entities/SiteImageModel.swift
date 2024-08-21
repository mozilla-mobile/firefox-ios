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

    // URL of the image (e.g. faviconURL, preferrably high resolution)
    private(set) var resourceURL: URL?

    // Loaded image asset
    public private(set) var image: UIImage?

    public init(id: UUID,
                imageType: SiteImageType,
                siteURL: URL,
                cacheKey: String? = nil,
                resourceURL: URL? = nil,
                image: UIImage? = nil) {
        self.id = id
        self.imageType = imageType
        self.siteURL = siteURL
        self.cacheKey = cacheKey
                        ?? SiteImageModel.generateCacheKey(siteURL: siteURL, resourceURL: resourceURL, type: imageType)
        self.resourceURL = resourceURL
        self.image = image
    }

    public init(siteImageModel: SiteImageModel,
                image: UIImage) {
        self = siteImageModel
        self.image = image
    }

    public init(siteImageModel: SiteImageModel,
                resourceURL: URL) {
        self = siteImageModel
        self.resourceURL = resourceURL
    }

    // FIXME Move this somewhere more appropriate
    /// Generates a cache key for the given image type by using its associated site URL or resource URL.
    /// - Parameters:
    ///   - siteURL: The website with which this image is associated.
    ///   - resourceURL: The remote URL of the image resource.
    ///   - type: The image type.
    /// - Returns: A cache key value for storing this image in an image cache.
    static func generateCacheKey(siteURL: URL, resourceURL: URL? = nil, type: SiteImageType) -> String {
        switch type {
        case .heroImage:
            // Always use the full site URL as the cache key for hero images
            return siteURL.absoluteString
        case .favicon:
            // If we already have a favicon url, use the url as the cache key
            if let faviconURL = resourceURL {
                return faviconURL.absoluteString
            }

            // Use the domain as the key to avoid caching and fetching unnecessary duplicates
            return siteURL.shortDomain ?? siteURL.shortDisplayString
        }
    }
}
