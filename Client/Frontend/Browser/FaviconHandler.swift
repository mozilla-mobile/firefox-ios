/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import SDWebImage
import Deferred

class FaviconHandler {
    static let MaximumFaviconSize = 1 * 1024 * 1024 // 1 MiB file size limit

    private var tabObservers: TabObservers!
    private let backgroundQueue = OperationQueue()

    init() {
        self.tabObservers = registerFor(.didLoadPageMetadata, queue: backgroundQueue)
    }

    deinit {
        unregister(tabObservers)
    }

    func loadFaviconURL(_ faviconURL: String, forTab tab: Tab) -> Deferred<Maybe<(Favicon, Data?)>> {
        guard let iconURL = URL(string: faviconURL), let currentURL = tab.url else {
            return deferMaybe(FaviconError())
        }

        let deferred = Deferred<Maybe<(Favicon, Data?)>>()
        let manager = SDWebImageManager.shared()
        let url = currentURL.absoluteString
        let site = Site(url: url, title: "")
        let options: SDWebImageOptions = tab.isPrivate ? SDWebImageOptions([.lowPriority, .cacheMemoryOnly]) : SDWebImageOptions([.lowPriority])

        var fetch: SDWebImageOperation? = nil

        let onProgress: SDWebImageDownloaderProgressBlock = { (receivedSize, expectedSize, _) -> Void in
            if receivedSize > FaviconHandler.MaximumFaviconSize || expectedSize > FaviconHandler.MaximumFaviconSize {
                fetch?.cancel()
            }
        }

        let onCompleted: SDInternalCompletionBlock = { (img, data, _, _, _, url) -> Void in
            guard let img = img, let urlString = url?.absoluteString else {
                deferred.fill(Maybe(failure: FaviconError()))
                return
            }

            let favicon = Favicon(url: urlString, date: Date())
            favicon.width = Int(img.size.width)
            favicon.height = Int(img.size.height)

            tab.favicons.append(favicon)

            if !tab.isPrivate, let appDelegate = UIApplication.shared.delegate as? AppDelegate, let profile = appDelegate.profile {
                profile.favicons.addFavicon(favicon, forSite: site).upon { _ in
                    deferred.fill(Maybe(success: (favicon, data)))
                }
            } else {
                deferred.fill(Maybe(success: (favicon, data)))
            }
        }

        fetch = manager.loadImage(with: iconURL, options: options, progress: onProgress, completed: onCompleted)
        return deferred
    }
}

extension FaviconHandler: TabEventHandler {
    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        tab.favicons.removeAll(keepingCapacity: false)
        guard let faviconURL = metadata.faviconURL else {
            return
        }

        loadFaviconURL(faviconURL, forTab: tab) >>== { (favicon, data) in
            TabEvent.post(.didLoadFavicon(favicon, with: data), for: tab)
        }
    }
}

class FaviconError: MaybeErrorType {
    internal var description: String {
        return "No Image Loaded"
    }
}
