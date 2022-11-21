// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage

class FaviconHandler {
    private let backgroundQueue = OperationQueue()

    init() {
        register(self, forTabEvents: .didLoadPageMetadata, .pageMetadataNotAvailable)
    }

    func getFaviconIconFrom(url faviconUrl: String,
                            domainLevelIconUrl: String,
                            completion: @escaping (Favicon?, ImageLoadingError?) -> Void ) {

        guard let faviconUrl = URL(string: faviconUrl),
              let domainLevelIconUrl = URL(string: domainLevelIconUrl) else {
            completion(nil, ImageLoadingError.iconUrlNotFound)
            return
        }

        ImageLoadingHandler.shared.getImageFromCacheOrDownload(with: faviconUrl,
                                                               limit: ImageLoadingConstants.MaximumFaviconSize) { image, error in
            guard error == nil else {

                ImageLoadingHandler.shared.getImageFromCacheOrDownload(with: domainLevelIconUrl, limit: ImageLoadingConstants.MaximumFaviconSize) { image, error in

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

    func loadFaviconURL(_ faviconUrl: String, forTab tab: Tab,
                        completion: @escaping (Favicon?, ImageLoadingError?) -> Void ) {

        guard let currentUrl = tab.url, !faviconUrl.isEmpty else {
            completion(nil, ImageLoadingError.iconUrlNotFound)
            return
        }

        let domainLevelIconUrl = currentUrl.domainURL.appendingPathComponent("favicon.ico")

        let onSuccess: (Favicon) -> Void = { [weak tab] (favicon) -> Void in
            tab?.favicons.append(favicon)
            completion(favicon, nil)
        }

        getFaviconIconFrom(url: faviconUrl,
                           domainLevelIconUrl: domainLevelIconUrl.absoluteString) {
            favicon, error in

            guard error == nil, let favicon = favicon else {
                completion(nil, ImageLoadingError.unableToFetchImage)
                return
            }

            onSuccess(favicon)
        }
    }
}

extension FaviconHandler: TabEventHandler {
    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        tab.favicons.removeAll(keepingCapacity: false)
        guard let faviconURL = metadata.faviconURL else { return }

        // This is necessary for tab favicons. Tab tray tabs favicon doesn't get updated without it
        loadFaviconURL(faviconURL, forTab: tab) { favicon, error in
            guard error == nil else { return }
            TabEvent.post(.didLoadFavicon(favicon), for: tab)
        }
    }

    func tabMetadataNotAvailable(_ tab: Tab) {
        tab.favicons.removeAll(keepingCapacity: false)
    }
}
