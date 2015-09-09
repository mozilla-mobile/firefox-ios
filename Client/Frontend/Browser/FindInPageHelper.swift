/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

protocol FindInPageHelperDelegate: class {
    func findInPageHelper(findInPageHelper: FindInPageHelper, didUpdateCurrentResult currentResult: Int)
    func findInPageHelper(findInPageHelper: FindInPageHelper, didUpdateTotalResults totalResults: Int)
}

class FindInPageHelper: BrowserHelper {
    weak var delegate: FindInPageHelperDelegate?
    private weak var browser: Browser?

    class func name() -> String {
        return "FindInPage"
    }

    required init(browser: Browser) {
        self.browser = browser

        if let path = NSBundle.mainBundle().pathForResource("FindInPage", ofType: "js"), source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
            let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
            browser.webView!.configuration.userContentController.addUserScript(userScript)
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "findInPageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        let data = message.body as! [String: Int]

        if let currentResult = data["currentResult"] {
            delegate?.findInPageHelper(self, didUpdateCurrentResult: currentResult)
        }

        if let totalResults = data["totalResults"] {
            delegate?.findInPageHelper(self, didUpdateTotalResults: totalResults)
        }
    }
}
