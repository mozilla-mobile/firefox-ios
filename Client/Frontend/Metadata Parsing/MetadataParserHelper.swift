/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import WebKit
import SDWebImage
import Deferred

private let log = Logger.browserLogger

class MetadataParserHelper: TabContentScript {
    static let FaviconDidLoad = "MetadataParserHelperFaviconDidLoad"

    static let MaximumFaviconSize = 1 * 1024 * 1024 // 1 MiB file size limit

    private weak var tab: Tab?
    private let profile: Profile

    class func name() -> String {
        return "MetadataParserHelper"
    }

    required init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.profile = profile

        tab.injectUserScriptWith(fileName: "page-metadata-parser")
        tab.injectUserScriptWith(fileName: "MetadataHelper")
    }

    func scriptMessageHandlerName() -> String? {
        return "metadataMessageHandler"
    }

    func loadFaviconURL(_ faviconURL: String) -> Deferred<Maybe<Favicon>> {
        guard let iconURL = URL(string: faviconURL), let currentURL = tab?.url else {
            return deferMaybe(FaviconError())
        }

        let deferred = Deferred<Maybe<Favicon>>()
        let manager = SDWebImageManager.shared()
        let url = currentURL.absoluteString
        let site = Site(url: url, title: "")
        let options: SDWebImageOptions = (tab?.isPrivate ?? true) ? SDWebImageOptions([.lowPriority, .cacheMemoryOnly]) : SDWebImageOptions([.lowPriority])

        var fetch: SDWebImageOperation? = nil

        let onProgress: SDWebImageDownloaderProgressBlock = { (receivedSize, expectedSize, _) -> Void in
            if receivedSize > MetadataParserHelper.MaximumFaviconSize || expectedSize > MetadataParserHelper.MaximumFaviconSize {
                fetch?.cancel()
            }
        }

        let onCompleted: SDInternalCompletionBlock = { (img, _, _, _, _, url) -> Void in
            guard let tab = self.tab, let img = img, let urlString = url?.absoluteString else {
                deferred.fill(Maybe(failure: FaviconError()))
                return
            }

            let favicon = Favicon(url: urlString, date: Date())
            favicon.width = Int(img.size.width)
            favicon.height = Int(img.size.height)

            if !tab.isPrivate {
                tab.favicons.append(favicon)
                self.profile.favicons.addFavicon(favicon, forSite: site).upon { _ in
                    deferred.fill(Maybe(success: favicon))
                }
            } else {
                tab.favicons.append(favicon)
                deferred.fill(Maybe(success: favicon))
            }
        }

        fetch = manager.loadImage(with: iconURL, options: options, progress: onProgress, completed: onCompleted)
        return deferred
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // Get the metadata out of the page-metadata-parser, and into a type safe struct as soon
        // as possible.
        guard let dict = message.body as? [String: Any],
            let tab = self.tab,
            let pageURL = tab.url?.displayURL,
            let pageMetadata = PageMetadata.fromDictionary(dict) else {
                log.debug("Page contains no metadata!")
                return
        }

        let userInfo: [String: Any] = [
            "isPrivate": self.tab?.isPrivate ?? true,
            "pageMetadata": pageMetadata,
            "tabURL": pageURL
        ]

        tab.pageMetadata = pageMetadata

        TabEvent.post(.didLoadPageMetadata(pageMetadata), for: tab)
        NotificationCenter.default.post(name: NotificationOnPageMetadataFetched, object: nil, userInfo: userInfo)

        if let faviconURL = pageMetadata.faviconURL {
            loadFaviconURL(faviconURL).uponQueue(DispatchQueue.main) { result in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: MetadataParserHelper.FaviconDidLoad), object: tab)
            }
        }
    }
}

class FaviconError: MaybeErrorType {
    internal var description: String {
        return "No Image Loaded"
    }
}
