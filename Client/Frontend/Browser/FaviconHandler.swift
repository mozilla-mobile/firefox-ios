// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage

class FaviconHandler {
    private let backgroundQueue = OperationQueue()

    func getFaviconIconFrom(url faviconUrl: String,
                            domainLevelIconUrl: String,
                            completion: @escaping (Favicon?, ImageLoadingError?) -> Void
    ) {
        guard let faviconUrl = URL(string: faviconUrl),
              let domainLevelIconUrl = URL(string: domainLevelIconUrl)
        else {
            completion(nil, ImageLoadingError.iconUrlNotFound)
            return
        }

        ImageLoadingHandler.shared.getImageFromCacheOrDownload(with: faviconUrl,
                                                               limit: ImageLoadingConstants.MaximumFaviconSize) { image, error in
            guard error == nil else {
                ImageLoadingHandler.shared.getImageFromCacheOrDownload(
                    with: domainLevelIconUrl,
                    limit: ImageLoadingConstants.MaximumFaviconSize
                ) { image, error in
                    guard error == nil else {
                        completion(nil, ImageLoadingError.unableToFetchImage)
                        return
                    }

                    guard let image = image else {
                        completion(nil, ImageLoadingError.unableToFetchImage)
                        return
                    }

                    let favicon = Favicon(url: domainLevelIconUrl.absoluteString,
                                          date: Date())
                    favicon.width = Int(image.size.width)
                    favicon.height = Int(image.size.height)
                    completion(favicon, nil)
                }

                return
            }

            guard let image = image else {
                completion(nil, ImageLoadingError.unableToFetchImage)
                return
            }

            let favicon = Favicon(url: faviconUrl.absoluteString, date: Date())
            favicon.width = Int(image.size.width)
            favicon.height = Int(image.size.height)
            completion(favicon, nil)
        }
    }
}
