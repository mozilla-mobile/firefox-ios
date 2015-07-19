/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared

class FaviconManagerError: ErrorType {
    let description: String
    init(description: String) {
        self.description = description
    }
    init(err: NSError) {
        self.description = err.description
    }
}

class FaviconManager : BrowserHelper {
    let profile: Profile!
    weak var browser: Browser?

    init(browser: Browser, profile: Profile) {
        self.profile = profile
        self.browser = browser

        if let path = NSBundle.mainBundle().pathForResource("Favicons", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) as? String {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
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

    func downloadIcon(icon: Favicon) -> Deferred<Result<Favicon>> {
        let deferred = Deferred<Result<Favicon>>()
        if let url = icon.url.asURL {
            let manager = SDWebImageManager.sharedManager()
            manager.downloadImageWithURL(url,
                options: SDWebImageOptions.LowPriority,
                progress: nil) { (img, err, cacheType, success, url) -> Void in
                    if let err = err {
                        deferred.fill(Result(failure: FaviconManagerError(err: err)))
                        return
                    }

                    if let img = img {
                        icon.width = Int(img.size.width)
                        icon.height = Int(img.size.height)
                        self.browser?.favicons.append(icon)
                    }

                    deferred.fill(Result(success: icon))
            }
        } else {
            deferred.fill(Result(failure: FaviconManagerError(description: "Invalid url \(icon.url)")))
        }
        return deferred
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        self.browser?.favicons.removeAll(keepCapacity: false)
        if let url = browser?.webView!.URL?.absoluteString {
            let site = Site(url: url, title: "")
            if let icons = message.body as? [String: Int] {
                // Download all the icons
                let deferreds = map(icons) { (iconUrl, iconType) -> Deferred<Result<Favicon>> in
                    let fav = Favicon(url: iconUrl,
                        date: NSDate(),
                        type: IconType(rawValue: iconType)!)
                    return self.downloadIcon(fav)
                }

                // When downloading is done, save them all.
                all(deferreds).upon({ results in
                    let favicons = results.filter { $0.isSuccess }.map { $0.successValue! }
                    self.profile.favicons.addFavicons(favicons, forSite: site)
                })
            }
        }
    }
}