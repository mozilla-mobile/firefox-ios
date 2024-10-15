// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum SiteImageError: Error, CustomStringConvertible, Equatable {
    case invalidHTML
    case noFaviconFound
    case noFaviconURLFound
    case unableToDownloadImage(String)
    case unableToCacheImage(String)
    case unableToRetrieveFromCache(String)
    case noURLInCache
    case noHeroImage
    case noImageInBundle
    case noLetterImage

    var description: String {
        switch self {
        case .invalidHTML:
            return "Failed to decode the data at the url as valid HTML"
        case .noFaviconFound:
            return "Failed to find a favicon at the provided url"
        case .noFaviconURLFound:
            return "Failed to find a favicon url in either the cache or from the web"
        case .unableToDownloadImage(let error):
            return "Unable to download image with reason: \(error)"
        case .unableToCacheImage(let error):
            return "Unable to cache image with reason: \(error)"
        case .unableToRetrieveFromCache(let error):
            return "Unable to retrieve image from cache with reason: \(error)"
        case .noURLInCache:
            return "The URL was not found in the cache"
        case .noHeroImage:
            return "No hero image was found"
        case .noImageInBundle:
            return "No image in bundle was found"
        case .noLetterImage:
            return "The first character is nil or empty so no letter image"
        }
    }
}
