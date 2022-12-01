// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

enum ImageError: Error, CustomStringConvertible {
    case unableToDownloadImage(String)
    case unableToCacheImage(String)
    case unableToRetrieveFromCache(String)

    var description: String {
        switch self {
        case .unableToDownloadImage(let error):
            return "Unable to download image with reason: \(error)"
        case .unableToCacheImage(let error):
            return "Unable to cache image with reason: \(error)"
        case .unableToRetrieveFromCache(let error):
            return "Unable to retrieve image from cache with reason: \(error)"
        }
    }
}
