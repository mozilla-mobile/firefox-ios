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
        let deferred = Deferred<Maybe<[Favicon]>>()
        var deferreds: [() -> Deferred<Maybe<Favicon>>]
        deferreds = favicons.map { favicon in
            return { () -> Deferred<Maybe<Favicon>> in
                if let url = NSURL(string: favicon.url) {
                    return self.getFavicon(tab, iconUrl: url, icon: favicon, profile: profile)
                }
                else {
                    return deferMaybe(FaviconError())
                }
            }
        }
        
        accumulate(deferreds) >>== { favicons in
                deferred.fill(Maybe(success: favicons))
        }
        
        return deferred
    }
    
    func getFavicon(tab: Tab, iconUrl: NSURL, icon: Favicon, profile: Profile) -> Deferred<Maybe<Favicon>> {
        let deferred = Deferred<Maybe<Favicon>>()
        let manager = SDWebImageManager.sharedManager()
        let options = tab.isPrivate ?
            [SDWebImageOptions.LowPriority, SDWebImageOptions.CacheMemoryOnly] : [SDWebImageOptions.LowPriority]
        
        if let currentURL = tab.url,
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
                                            
                                            tab.favicons.append(fav)
                                            if !tab.isPrivate {
                                                self.profile.favicons.addFavicon(fav, forSite: site).upon { _ in
                                                    deferred.fill(Maybe(success: fav))
                                                }
                                                if tab.favicons.isEmpty {
                                                    self.makeFaviconAvailable(tab, atURL: currentURL, favicon: fav, withImage: img)
                                                }
                                            }
                                            else {
                                                deferred.fill(Maybe(success: fav))
                                            }
            })
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
