/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage

class FaviconManager : BrowserHelper {
    var profile: Profile!
    weak var browser: Browser?

    init(browser: Browser, profile: Profile) {
        self.profile = profile
        self.browser = browser

        if let path = NSBundle.mainBundle().pathForResource("Favicons", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                browser.webView.configuration.userContentController.addUserScript(userScript)
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
        println("DEBUG: faviconsMessageHandler message: \(message.body)")

        if let url = browser?.webView.URL?.absoluteString {
            let site = Site(url: url, title: "")
            if let icons = message.body as? [String: Int] {
                for icon in icons {
                    let fav = Favicon(url: icon.0, date: NSDate(), type: IconType(rawValue: icon.1)!)
                    profile.favicons.add(fav, site: site, complete: { (success) -> Void in
                        return
                    })
                }
            }
        }
    }
}