/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import Storage
import WebImage
import Deferred
import Sync


class FaviconManager : TabHelper {
    static let FaviconDidLoad = "FaviconManagerFaviconDidLoad"
    private let queue = dispatch_queue_create("FaviconManager", DISPATCH_QUEUE_CONCURRENT)
    
    let profile: Profile!
    weak var tab: Tab?

    init(tab: Tab, profile: Profile) {
        self.profile = profile
        self.tab = tab

        if let path = NSBundle.mainBundle().pathForResource("Favicons", ofType: "js") {
            if let source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
                let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
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
    
    internal class FaviconError: MaybeErrorType {
        internal var description: String {
            return "No Image Loaded"
        }
    }
    
    private func loadFavicons(tab: Tab, profile: Profile, favicons: [Favicon]) -> Deferred<Maybe<[Favicon]>> {
        var oldIcons: [Favicon] = favicons
        let deferred = Deferred<Maybe<[Favicon]>>()
        dispatch_async(queue) { _ in
            var deferreds = [Deferred<Maybe<Favicon>>]()
            deferreds = favicons.map { self.getFavicon(tab, icon: $0, profile: profile) }
            all(deferreds).bind({ (results: [Maybe<Favicon>]) -> Deferred<Maybe<[Favicon]>> in
                for result in results {
                    if let icon = result.successValue {
                        oldIcons.append(icon)
                    }
                }
                
                oldIcons = oldIcons.sort {
                    return $0.width > $1.width
                }
                
                return deferMaybe(oldIcons)
            }).upon({ (result: Maybe<[Favicon]>) in
                deferred.fill(result)
                return
            })
        }
        
        return deferred
    }
    
    func getFavicon(tab: Tab, icon: Favicon, profile: Profile) -> Deferred<Maybe<Favicon>> {
        let deferred = Deferred<Maybe<Favicon>>()
        let manager = SDWebImageManager.sharedManager()
        let options = tab.isPrivate ?
            [SDWebImageOptions.LowPriority, SDWebImageOptions.CacheMemoryOnly] : [SDWebImageOptions.LowPriority]
        
        if let iconUrl = NSURL(string: icon.url),
            let currentURL = tab.url,
            let url = tab.url?.absoluteString {
            let site = Site(url: url, title: "")
            manager.downloadImageWithURL(iconUrl,
                                         options: SDWebImageOptions(options),
                                         progress: nil,
                                         completed: { (img, err, cacheType, success, url) -> Void in
                                            let fav = Favicon(url: url.absoluteString,
                                                date: NSDate(),
                                                type: icon.type)
                                            
                                            if let img = img {
                                                fav.width = Int(img.size.width)
                                                fav.height = Int(img.size.height)
                                            } else {
                                                deferred.fill(Maybe(failure: FaviconError()))
                                                return
                                            }
                                            
                                            if !tab.isPrivate {
                                                self.profile.favicons.addFavicon(fav, forSite: site)
                                                if tab.favicons.isEmpty {
                                                    self.makeFaviconAvailable(tab, atURL: currentURL, favicon: fav, withImage: img)
                                                }
                                            }
                                            tab.favicons.append(fav)
                                            deferred.fill(Maybe(success: fav))
            })
        } else {
            return deferMaybe(FaviconFetcherErrorType(description: "Invalid URL \(icon.url)"))
        }
        
        return deferred
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        self.tab?.favicons.removeAll(keepCapacity: false)
        if let tab = self.tab,
        let currentURL = tab.url {
                var favicons = [Favicon]()
                if let icons = message.body as? [String: Int] {
                    for icon in icons {
                        if let _ = NSURL(string: icon.0), iconType = IconType(rawValue: icon.1) {
                            let favicon = Favicon(url: icon.0, date: NSDate(), type: iconType)
                            favicons.append(favicon)
                        }
                    }
                }
            loadFavicons(tab, profile: profile, favicons: favicons).uponQueue(dispatch_get_main_queue()) { result in
                if let result = result.successValue {
                    if result.count == 1 && favicons[0].type == .Guess {
                        // No favicon is indicated in the HTML
                        self.noFaviconAvailable(tab, atURL: currentURL)
                    }
                }
                NSNotificationCenter.defaultCenter().postNotificationName(FaviconManager.FaviconDidLoad, object: nil)
            }
        }
    }

    func makeFaviconAvailable(tab: Tab, atURL url: NSURL, favicon: Favicon, withImage image: UIImage) {
        let helper = tab.getHelper(name: "SpotlightHelper") as? SpotlightHelper
        helper?.updateImage(image, forURL: url)
    }

    func noFaviconAvailable(tab: Tab, atURL url: NSURL) {
        let helper = tab.getHelper(name: "SpotlightHelper") as? SpotlightHelper
        helper?.updateImage(forURL: url)

    }
}
