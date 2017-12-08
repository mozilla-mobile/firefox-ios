/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import Storage
import SDWebImage
import Deferred
import Sync

class FaviconManager: TabContentScript {
    static let FaviconDidLoad = "FaviconManagerFaviconDidLoad"
    
    let profile: Profile!
    weak var tab: Tab?
    
    static let maximumFaviconSize = 1 * 1024 * 1024 // 1 MiB file size limit

    init(tab: Tab, profile: Profile) {
        self.profile = profile
        self.tab = tab

        if let path = Bundle.main.path(forResource: "Favicons", ofType: "js") {
            if let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
                let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
                tab.webView!.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    class func name() -> String {
        return "FaviconsManager"
    }

    func scriptMessageHandlerName() -> String? {
        return "faviconsMessageHandler"
    }
    
    fileprivate func loadFavicons(_ tab: Tab, profile: Profile, favicons: [Favicon]) -> Deferred<[Maybe<Favicon>]> {
        var deferreds: [() -> Deferred<Maybe<Favicon>>]
        deferreds = favicons.map { favicon in
            return { [weak tab] () -> Deferred<Maybe<Favicon>> in
                if  let tab = tab,
                    let url = URL(string: favicon.url),
                    let currentURL = tab.url {
                    return self.getFavicon(tab, iconUrl: url, currentURL: currentURL, icon: favicon, profile: profile)
                } else {
                    return deferMaybe(FaviconError())
                }
            }
        }
        return all(deferreds.map({$0()}))
    }
    
    func getFavicon(_ tab: Tab, iconUrl: URL, currentURL: URL, icon: Favicon, profile: Profile) -> Deferred<Maybe<Favicon>> {
        let deferred = Deferred<Maybe<Favicon>>()
        let manager = SDWebImageManager.shared()
        let options: [SDWebImageOptions] = tab.isPrivate ? [.lowPriority, .cacheMemoryOnly] : [.lowPriority]
        let url = currentURL.absoluteString
        let site = Site(url: url, title: "")

        weak var tab = tab

        func loadImageCompleted(_ img: UIImage?, _ url: URL?) {
            guard let tab = tab, let img = img, let urlString = url?.absoluteString else {
                deferred.fill(Maybe(failure: FaviconError()))
                return
            }

            let fav = Favicon(url: urlString, date: Date(), type: icon.type)
            fav.width = Int(img.size.width)
            fav.height = Int(img.size.height)

            if !tab.isPrivate {
                if tab.favicons.isEmpty {
                    self.makeFaviconAvailable(tab, atURL: currentURL, favicon: fav, withImage: img)
                }
                tab.favicons.append(fav)
                self.profile.favicons.addFavicon(fav, forSite: site).upon { _ in
                    deferred.fill(Maybe(success: fav))
                }
            } else {
                tab.favicons.append(fav)
                deferred.fill(Maybe(success: fav))
            }
        }

        var fetch: SDWebImageOperation? = nil
        fetch = manager.loadImage(with: iconUrl, options: SDWebImageOptions(options),
                                  progress: { (receivedSize, expectedSize, _) in
                                    if receivedSize > FaviconManager.maximumFaviconSize || expectedSize > FaviconManager.maximumFaviconSize {
                                        fetch?.cancel()
                                    }
                                  },
                                  completed: {  (img, _, _, _, _, url) in
                                    loadImageCompleted(img, url)
                                  })
        return deferred
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        self.tab?.favicons.removeAll(keepingCapacity: false)
        if let tab = self.tab, let currentURL = tab.url {
            var favicons = [Favicon]()
            if let icons = message.body as? [String: Int] {
                for icon in icons {
                    if let _ = URL(string: icon.0), let iconType = IconType(rawValue: icon.1) {
                        let favicon = Favicon(url: icon.0, date: Date(), type: iconType)
                        favicons.append(favicon)
                    }
                }
            }
            loadFavicons(tab, profile: profile, favicons: favicons).uponQueue(DispatchQueue.main) { result in
                let results = result.flatMap({ $0.successValue })
                let faviconsReadOnly = favicons
                if results.count == 1 && faviconsReadOnly[0].type == .guess {
                    // No favicon is indicated in the HTML
                    self.noFaviconAvailable(tab, atURL: currentURL as URL)
                }

                NotificationCenter.default.post(name: NSNotification.Name(rawValue: FaviconManager.FaviconDidLoad), object: tab)
            }
        }
    }

    func makeFaviconAvailable(_ tab: Tab, atURL url: URL, favicon: Favicon, withImage image: UIImage) {
        // XXX: Bug 1390200 - Disable NSUserActivity/CoreSpotlight temporarily
        // let helper = tab.getHelper(name: "SpotlightHelper") as? SpotlightHelper
        // helper?.updateImage(image, forURL: url)
    }

    func noFaviconAvailable(_ tab: Tab, atURL url: URL) {
        // XXX: Bug 1390200 - Disable NSUserActivity/CoreSpotlight temporarily
        // let helper = tab.getHelper(name: "SpotlightHelper") as? SpotlightHelper
        // helper?.updateImage(forURL: url)
    }
}

class FaviconError: MaybeErrorType {
    internal var description: String {
        return "No Image Loaded"
    }
}
