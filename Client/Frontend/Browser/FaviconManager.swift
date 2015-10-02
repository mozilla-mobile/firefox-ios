/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage

class FaviconManager : BrowserHelper {
    let profile: Profile!
    weak var browser: Browser?

    init(browser: Browser, profile: Profile) {
        self.profile = profile
        self.browser = browser

        if let path = NSBundle.mainBundle().pathForResource("Favicons", ofType: "js") {
            if let source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
                let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                browser.webView!.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    class func name() -> String {
        return "FaviconsManager"
    }

    func scriptMessageHandlerName() -> String? {
        return "faviconsMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        let manager = SDWebImageManager.sharedManager()
        self.browser?.favicons.removeAll(keepCapacity: false)
        if let url = browser?.webView!.URL?.absoluteString {
            let site = Site(url: url, title: "")
            if let icons = message.body as? [String: Int] {
                for icon in icons {
                    if let iconUrl = NSURL(string: icon.0), let browser = self.browser {
                        let options = browser.isPrivate ? [SDWebImageOptions.LowPriority, SDWebImageOptions.CacheMemoryOnly] : [SDWebImageOptions.LowPriority]
                        manager.downloadImageWithURL(iconUrl, options: SDWebImageOptions(options), progress: nil, completed: { (img, err, cacheType, success, url) -> Void in
                            let fav = Favicon(url: url.absoluteString,
                                date: NSDate(),
                                type: IconType(rawValue: icon.1)!)

                            if let img = img {
                                fav.width = Int(img.size.width)
                                fav.height = Int(img.size.height)
                            } else {
                                return
                            }

                            browser.favicons.append(fav)
                            if !browser.isPrivate {
                                self.profile.favicons.addFavicon(fav, forSite: site)
                            }
                        })
                    }
                }
            }
        }
    }
}
