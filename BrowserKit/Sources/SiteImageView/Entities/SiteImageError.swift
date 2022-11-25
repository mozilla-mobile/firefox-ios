// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

enum SiteImageError: Error {
    case invalidHTML
    case noFaviconFound
    case unableToDownloadImage(String)

    var description: String {
        switch self {
        case .invalidHTML:
            return "Failed to decode the data at the url as valid HTML"
        case .noFaviconFound:
            return "Failed to find a favicon at the provided url"
        case .unableToDownloadImage(let error):
            return "Unable to download image with reason: \(error)"
        }
    }
}
