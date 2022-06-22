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

        ImageLoadingHandler.getImageFromCacheOrDownload(with: faviconUrl, limit: ImageLoadingConstants.MaximumFaviconSize) { image, error in

            guard error == nil else {

                ImageLoadingHandler.getImageFromCacheOrDownload(with: domainLevelIconUrl, limit: ImageLoadingConstants.MaximumFaviconSize) { image, error in

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

                    ImageLoadingHandler.saveImageToCache(img: image,
                                                    key: domainLevelIconUrl.absoluteString)
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
            ImageLoadingHandler.saveImageToCache(img: image,
                                            key: domainLevelIconUrl.absoluteString)
            completion(favicon, nil)
        }

    }

    func loadFaviconURL(_ faviconUrl: String, forTab tab: Tab,
                        completion: @escaping (Favicon?, ImageLoadingError?) -> Void ) {

        guard let currencrtUrl = tab.url, !faviconUrl.isEmpty else {
            completion(nil, ImageLoadingError.iconUrlNotFound)
            return
        }

        let domainLevelIconUrl = currencrtUrl.domainURL.appendingPathComponent("favicon.ico")
        let site = Site(url: currencrtUrl.absoluteString, title: "")
    
        let onSuccess: (Favicon) -> Void = { [weak tab] (favicon) -> Void in
            tab?.favicons.append(favicon)

            guard !(tab?.isPrivate ?? true), let appDelegate = UIApplication.shared.delegate as? AppDelegate, let profile = appDelegate.profile else {
                completion(favicon, nil)
                return
            }

            profile.favicons.addFavicon(favicon, forSite: site) >>> {                completion(favicon, nil)
            }
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
        guard let faviconURL = metadata.faviconURL else {
            return
        }

        loadFaviconURL(faviconURL, forTab: tab) { favicon, error in
            guard error == nil else { return }
            TabEvent.post(.didLoadFavicon(favicon), for: tab)
        }

    }
    func tabMetadataNotAvailable(_ tab: Tab) {
        tab.favicons.removeAll(keepingCapacity: false)
    }
}
